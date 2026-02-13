import Foundation
import UIKit

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

@MainActor
public protocol PlayerGestureHandler: AnyObject {
    var gestureType: PlayerGestureType { get }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection)
}

@MainActor
public protocol PlayerGestureService: CCLCompService {

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
