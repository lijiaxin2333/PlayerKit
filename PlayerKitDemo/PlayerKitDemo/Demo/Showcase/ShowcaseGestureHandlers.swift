import Foundation
import UIKit
import BizPlayerKit

@MainActor
final class ShowcaseSingleTapHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .singleTap }
    weak var delegate: ShowcaseGestureDelegate?

    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        delegate?.didSingleTap()
    }
}

@MainActor
final class ShowcaseDoubleTapHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .doubleTap }
    weak var delegate: ShowcaseGestureDelegate?

    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        delegate?.didDoubleTap()
    }
}

@MainActor
final class ShowcasePanHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .pan }
    weak var delegate: ShowcaseGestureDelegate?

    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let pan = recognizer as? UIPanGestureRecognizer else { return }

        switch pan.state {
        case .began:
            delegate?.didBeginPan(direction: direction)
        case .changed:
            let translation = pan.translation(in: pan.view)
            let delta = Float(-translation.y / (pan.view?.bounds.height ?? 400))
            delegate?.didChangePan(direction: direction, delta: delta)
            pan.setTranslation(.zero, in: pan.view)
        case .ended, .cancelled:
            delegate?.didEndPan(direction: direction)
        default:
            break
        }
    }
}

@MainActor
final class ShowcaseLongPressHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .longPress }
    weak var delegate: ShowcaseGestureDelegate?

    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        switch recognizer.state {
        case .began:
            delegate?.didBeginLongPress()
        case .ended, .cancelled:
            delegate?.didEndLongPress()
        default:
            break
        }
    }
}

@MainActor
final class ShowcasePinchHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .pinch }
    weak var delegate: ShowcaseGestureDelegate?

    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let pinch = recognizer as? UIPinchGestureRecognizer else { return }
        if pinch.state == .ended {
            delegate?.didPinch(scale: pinch.scale)
        }
    }
}

@MainActor
protocol ShowcaseGestureDelegate: AnyObject {
    func didSingleTap()
    func didDoubleTap()
    func didBeginPan(direction: PlayerPanDirection)
    func didChangePan(direction: PlayerPanDirection, delta: Float)
    func didEndPan(direction: PlayerPanDirection)
    func didBeginLongPress()
    func didEndLongPress()
    func didPinch(scale: CGFloat)
}
