import Foundation
import UIKit
import BizPlayerKit

// MARK: - Gesture Types

public enum PlayerGestureType: Int {
    case singleTap = 0
    case doubleTap
    case pan
    case pinch
    case longPress
}

public enum PlayerPanDirection: Int {
    case unknown = 0
    case horizontal
    case verticalLeft
    case verticalRight
}

// MARK: - Gesture Events

public extension Event {
    /// 单击手势
    static let playerGestureSingleTap: Event = "PlayerGestureSingleTap"
    /// 双击手势
    static let playerGestureDoubleTap: Event = "PlayerGestureDoubleTap"
    /// 滑动手势
    static let playerGesturePan: Event = "PlayerGesturePan"
    /// 捏合手势
    static let playerGesturePinch: Event = "PlayerGesturePinch"
    /// 长按手势
    static let playerGestureLongPress: Event = "PlayerGestureLongPress"
}

// MARK: - Gesture Handler Protocol

@MainActor
public protocol PlayerGestureHandler: AnyObject {
    var gestureType: PlayerGestureType { get }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection)
}

// MARK: - Gesture Service Protocol

@MainActor
public protocol PlayerGestureService: PluginService {

    var gestureView: UIView? { get set }

    var isEnabled: Bool { get set }

    func addHandler(_ handler: PlayerGestureHandler)

    func removeHandler(_ handler: PlayerGestureHandler)

    func disableGesture(_ type: PlayerGestureType, forScene scene: String)

    func enableGesture(_ type: PlayerGestureType, forScene scene: String)

    var isSingleTapEnabled: Bool { get set }

    var isDoubleTapEnabled: Bool { get set }

    var isPanEnabled: Bool { get set }

    var isLongPressEnabled: Bool { get set }

    var isPinchEnabled: Bool { get set }
}
