import Foundation
import UIKit
import PlayerKit
import AVFoundation

@MainActor
/**
 * 字幕插件，支持加载 SRT/VTT 字幕、解析时间轴并随播放进度更新显示
 */
public final class PlayerSubtitlePlugin: BasePlugin, PlayerSubtitleService {

    /** 字幕是否启用，变更时同步控制字幕视图显隐 */
    public var isEnabled: Bool = false {
        didSet { subtitleLabel.isHidden = !isEnabled }
    }

    /** 当前选中的字幕项 */
    public private(set) var currentSubtitle: PlayerSubtitleItem?
    /** 已加载的字幕列表 */
    public private(set) var availableSubtitles: [PlayerSubtitleItem] = []
    /** 当前正在显示的字幕 cue */
    public private(set) var currentCue: PlayerSubtitleCue?
    /** 是否存在内嵌字幕 */
    public private(set) var hasEmbeddedSubtitle: Bool = false

    /** 字幕字号，变更时更新标签字体 */
    public var fontSize: CGFloat = 16 {
        didSet { subtitleLabel.font = .systemFont(ofSize: fontSize, weight: .medium) }
    }

    /** 字幕颜色 */
    public var fontColor: UIColor = .white {
        didSet { subtitleLabel.textColor = fontColor }
    }

    /** 字幕背景色 */
    public var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.6) {
        didSet { subtitleLabel.backgroundColor = backgroundColor }
    }

    /** 字幕距离底部的偏移 */
    public var bottomOffset: CGFloat = 40

    /** 字幕显示用的 UILabel */
    private let subtitleLabel = UILabel()
    /** 当前字幕的 cue 列表 */
    private var cues: [PlayerSubtitleCue] = []
    /** 播放进度时间观察者 */
    private var timeObserver: AnyObject?

    @PlayerPlugin private var engine: PlayerEngineCoreService?

    /** 对外暴露的字幕视图 */
    public var subtitleView: UIView? { subtitleLabel }

    public required override init() {
        super.init()
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.font = .systemFont(ofSize: fontSize, weight: .medium)
        subtitleLabel.textColor = fontColor
        subtitleLabel.backgroundColor = backgroundColor
        subtitleLabel.layer.cornerRadius = 4
        subtitleLabel.clipsToBounds = true
        subtitleLabel.isHidden = true
    }

    /**
     * 加载字幕项，若为新项则加入列表并切换
     */
    public func loadSubtitle(_ item: PlayerSubtitleItem) {
        if !availableSubtitles.contains(where: { $0.id == item.id }) {
            availableSubtitles.append(item)
        }
        switchSubtitle(to: item)
    }

    /**
     * 从 URL 加载字幕
     */
    public func loadSubtitle(from url: URL, format: PlayerSubtitleFormat, language: String) {
        let item = PlayerSubtitleItem(id: url.absoluteString, language: language, displayName: language, url: url, format: format)
        loadSubtitle(item)
    }

    /**
     * 切换到指定字幕项，重新解析并启动时间观察
     */
    public func switchSubtitle(to item: PlayerSubtitleItem) {
        currentSubtitle = item
        cues = []
        currentCue = nil
        subtitleLabel.text = nil

        guard let url = item.url else { return }

        Task { [weak self] in
            guard let self = self else { return }
            let parsed = await self.parseSubtitleFile(url: url, format: item.format)
            self.cues = parsed
            self.startTimeObserver()
        }
    }

    /**
     * 移除当前字幕
     */
    public func removeSubtitle() {
        currentSubtitle = nil
        cues = []
        currentCue = nil
        subtitleLabel.text = nil
        stopTimeObserver()
    }

    /**
     * 移除所有字幕
     */
    public func removeAllSubtitles() {
        removeSubtitle()
        availableSubtitles.removeAll()
    }

    /**
     * 启动播放进度时间观察，用于同步显示当前 cue
     */
    private func startTimeObserver() {
        stopTimeObserver()
        timeObserver = engine?.addPeriodicTimeObserver(interval: 0.25, queue: .main) { [weak self] time in
            MainActor.assumeIsolated {
                self?.updateCue(at: time)
            }
        }
    }

    /**
     * 停止播放进度时间观察
     */
    private func stopTimeObserver() {
        if let observer = timeObserver {
            engine?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    /**
     * 根据当前播放时间更新显示的 cue
     */
    private func updateCue(at time: TimeInterval) {
        let matched = cues.first { time >= $0.startTime && time <= $0.endTime }
        if matched?.startTime != currentCue?.startTime || matched?.endTime != currentCue?.endTime {
            currentCue = matched
            subtitleLabel.text = matched?.text
            subtitleLabel.isHidden = !isEnabled || matched == nil
        }
    }

    /**
     * 异步解析字幕文件内容为 cue 列表
     */
    private func parseSubtitleFile(url: URL, format: PlayerSubtitleFormat) async -> [PlayerSubtitleCue] {
        guard let data = try? Data(contentsOf: url),
              let content = String(data: data, encoding: .utf8) else { return [] }

        switch format {
        case .srt:
            return parseSRT(content)
        case .vtt:
            return parseVTT(content)
        default:
            return []
        }
    }

    /**
     * 解析 SRT 格式字幕
     */
    private func parseSRT(_ content: String) -> [PlayerSubtitleCue] {
        var result: [PlayerSubtitleCue] = []
        let blocks = content.components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard lines.count >= 3 else { continue }
            let timeLine = lines[1]
            let parts = timeLine.components(separatedBy: " --> ")
            guard parts.count == 2 else { continue }
            guard let start = parseTimeCode(parts[0].trimmingCharacters(in: .whitespaces)),
                  let end = parseTimeCode(parts[1].trimmingCharacters(in: .whitespaces)) else { continue }
            let text = lines.dropFirst(2).joined(separator: "\n")
            result.append(PlayerSubtitleCue(startTime: start, endTime: end, text: text))
        }
        return result
    }

    /**
     * 解析 VTT 格式字幕
     */
    private func parseVTT(_ content: String) -> [PlayerSubtitleCue] {
        var result: [PlayerSubtitleCue] = []
        let blocks = content.components(separatedBy: "\n\n")
        for block in blocks {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard let timeLineIdx = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
            let timeLine = lines[timeLineIdx]
            let parts = timeLine.components(separatedBy: " --> ")
            guard parts.count == 2 else { continue }
            guard let start = parseTimeCode(parts[0].trimmingCharacters(in: .whitespaces)),
                  let end = parseTimeCode(parts[1].trimmingCharacters(in: .whitespaces)) else { continue }
            let text = lines.dropFirst(timeLineIdx + 1).joined(separator: "\n")
            guard !text.isEmpty else { continue }
            result.append(PlayerSubtitleCue(startTime: start, endTime: end, text: text))
        }
        return result
    }

    /**
     * 解析时间码字符串为秒数
     */
    private func parseTimeCode(_ str: String) -> TimeInterval? {
        let cleaned = str.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.components(separatedBy: ":")
        guard parts.count >= 2 else { return nil }
        if parts.count == 3 {
            guard let h = Double(parts[0]), let m = Double(parts[1]), let s = Double(parts[2]) else { return nil }
            return h * 3600 + m * 60 + s
        } else {
            guard let m = Double(parts[0]), let s = Double(parts[1]) else { return nil }
            return m * 60 + s
        }
    }
}
