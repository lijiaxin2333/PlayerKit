import Foundation
import UIKit
import AVFoundation

@MainActor
public final class PlayerSubtitleComp: CCLBaseComp, PlayerSubtitleService {

    public var isEnabled: Bool = false {
        didSet { subtitleLabel.isHidden = !isEnabled }
    }

    public private(set) var currentSubtitle: PlayerSubtitleItem?
    public private(set) var availableSubtitles: [PlayerSubtitleItem] = []
    public private(set) var currentCue: PlayerSubtitleCue?
    public private(set) var hasEmbeddedSubtitle: Bool = false

    public var fontSize: CGFloat = 16 {
        didSet { subtitleLabel.font = .systemFont(ofSize: fontSize, weight: .medium) }
    }

    public var fontColor: UIColor = .white {
        didSet { subtitleLabel.textColor = fontColor }
    }

    public var backgroundColor: UIColor = UIColor.black.withAlphaComponent(0.6) {
        didSet { subtitleLabel.backgroundColor = backgroundColor }
    }

    public var bottomOffset: CGFloat = 40

    private let subtitleLabel = UILabel()
    private var cues: [PlayerSubtitleCue] = []
    private var timeObserver: AnyObject?

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engine: PlayerEngineCoreService?

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

    public func loadSubtitle(_ item: PlayerSubtitleItem) {
        if !availableSubtitles.contains(where: { $0.id == item.id }) {
            availableSubtitles.append(item)
        }
        switchSubtitle(to: item)
    }

    public func loadSubtitle(from url: URL, format: PlayerSubtitleFormat, language: String) {
        let item = PlayerSubtitleItem(id: url.absoluteString, language: language, displayName: language, url: url, format: format)
        loadSubtitle(item)
    }

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

    public func removeSubtitle() {
        currentSubtitle = nil
        cues = []
        currentCue = nil
        subtitleLabel.text = nil
        stopTimeObserver()
    }

    public func removeAllSubtitles() {
        removeSubtitle()
        availableSubtitles.removeAll()
    }

    private func startTimeObserver() {
        stopTimeObserver()
        timeObserver = engine?.addPeriodicTimeObserver(interval: 0.25, queue: .main) { [weak self] time in
            self?.updateCue(at: time)
        }
    }

    private func stopTimeObserver() {
        if let observer = timeObserver {
            engine?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func updateCue(at time: TimeInterval) {
        let matched = cues.first { time >= $0.startTime && time <= $0.endTime }
        if matched?.startTime != currentCue?.startTime || matched?.endTime != currentCue?.endTime {
            currentCue = matched
            subtitleLabel.text = matched?.text
            subtitleLabel.isHidden = !isEnabled || matched == nil
        }
    }

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
