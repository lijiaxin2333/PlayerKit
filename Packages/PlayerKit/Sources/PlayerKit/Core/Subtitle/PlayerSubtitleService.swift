import Foundation
import UIKit

public enum PlayerSubtitleFormat: Int {
    case srt = 0
    case vtt
    case ass
    case embedded
}

public struct PlayerSubtitleItem: Sendable {
    public var id: String
    public var language: String
    public var displayName: String
    public var url: URL?
    public var format: PlayerSubtitleFormat
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

public struct PlayerSubtitleCue: Sendable {
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    public var text: String

    public init(startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

@MainActor
public protocol PlayerSubtitleService: PluginService {

    var isEnabled: Bool { get set }

    var currentSubtitle: PlayerSubtitleItem? { get }

    var availableSubtitles: [PlayerSubtitleItem] { get }

    var subtitleView: UIView? { get }

    var fontSize: CGFloat { get set }

    var fontColor: UIColor { get set }

    var backgroundColor: UIColor { get set }

    var bottomOffset: CGFloat { get set }

    func loadSubtitle(_ item: PlayerSubtitleItem)

    func loadSubtitle(from url: URL, format: PlayerSubtitleFormat, language: String)

    func switchSubtitle(to item: PlayerSubtitleItem)

    func removeSubtitle()

    func removeAllSubtitles()

    var hasEmbeddedSubtitle: Bool { get }

    var currentCue: PlayerSubtitleCue? { get }
}
