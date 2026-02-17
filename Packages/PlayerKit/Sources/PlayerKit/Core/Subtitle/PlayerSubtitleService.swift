import Foundation
import UIKit

/**
 * 字幕格式枚举
 */
public enum PlayerSubtitleFormat: Int, Sendable {
    /** SRT 格式 */
    case srt = 0
    /** VTT 格式 */
    case vtt
    /** ASS 格式 */
    case ass
    /** 内嵌字幕 */
    case embedded
}

/**
 * 字幕项，描述一条字幕的来源、语言和格式
 */
public struct PlayerSubtitleItem: Sendable {
    /** 唯一标识 */
    public var id: String
    /** 语言 */
    public var language: String
    /** 显示名称 */
    public var displayName: String
    /** 字幕文件 URL */
    public var url: URL?
    /** 字幕格式 */
    public var format: PlayerSubtitleFormat
    /** 是否为内嵌字幕 */
    public var isEmbedded: Bool

    public init(id: String, language: String, displayName: String, url: URL? = nil, format: PlayerSubtitleFormat = .srt, isEmbedded: Bool = false) {
        self.id = id
        self.language = language
        self.displayName = displayName
        self.url = url
        self.format = format
        self.isEmbedded = isEmbedded
    }
}

/**
 * 字幕 cue，单条字幕的时间范围和文本
 */
public struct PlayerSubtitleCue: Sendable {
    /** 开始时间（秒） */
    public var startTime: TimeInterval
    /** 结束时间（秒） */
    public var endTime: TimeInterval
    /** 字幕文本 */
    public var text: String

    public init(startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

@MainActor
/**
 * 字幕服务协议，提供字幕加载、切换、样式及视图访问能力
 */
public protocol PlayerSubtitleService: PluginService {

    /** 字幕是否启用 */
    var isEnabled: Bool { get set }

    /** 当前选中的字幕项 */
    var currentSubtitle: PlayerSubtitleItem? { get }

    /** 已加载的字幕列表 */
    var availableSubtitles: [PlayerSubtitleItem] { get }

    /** 字幕显示视图 */
    var subtitleView: UIView? { get }

    /** 字幕字号 */
    var fontSize: CGFloat { get set }

    /** 字幕颜色 */
    var fontColor: UIColor { get set }

    /** 字幕背景色 */
    var backgroundColor: UIColor { get set }

    /** 字幕距离底部的偏移 */
    var bottomOffset: CGFloat { get set }

    /**
     * 加载字幕项
     */
    func loadSubtitle(_ item: PlayerSubtitleItem)

    /**
     * 从 URL 加载字幕
     */
    func loadSubtitle(from url: URL, format: PlayerSubtitleFormat, language: String)

    /**
     * 切换到指定字幕
     */
    func switchSubtitle(to item: PlayerSubtitleItem)

    /**
     * 移除当前字幕
     */
    func removeSubtitle()

    /**
     * 移除所有字幕
     */
    func removeAllSubtitles()

    /** 是否存在内嵌字幕 */
    var hasEmbeddedSubtitle: Bool { get }

    /** 当前显示的 cue */
    var currentCue: PlayerSubtitleCue? { get }
}
