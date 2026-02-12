import Foundation
import UIKit

@MainActor
public final class PlayerGestureComp: CCLBaseComp, PlayerGestureService {

    private var handlers: [PlayerGestureType: [PlayerGestureHandler]] = [:]
    private var disabledGestures: [String: Set<PlayerGestureType>] = [:]

    private var singleTapGR: UITapGestureRecognizer?
    private var doubleTapGR: UITapGestureRecognizer?
    private var panGR: UIPanGestureRecognizer?
    private var pinchGR: UIPinchGestureRecognizer?
    private var longPressGR: UILongPressGestureRecognizer?

    private weak var _gestureView: UIView?
    private var _isEnabled: Bool = true

    private var _isExternalGestureView: Bool = false

    public var gestureView: UIView? {
        get { _gestureView }
        set {
            removeAllGestureRecognizers()
            if let nv = newValue {
                _gestureView = nv
                _isExternalGestureView = true
                setupGestureRecognizers()
            } else {
                _isExternalGestureView = false
                _gestureView = nil
                rebindPlayerView()
            }
        }
    }

    private func rebindPlayerView() {
        guard let engine = context?.resolveService(PlayerEngineCoreService.self),
              let pv = engine.playerView else { return }
        pv.isUserInteractionEnabled = true
        _gestureView = pv
        setupGestureRecognizers()
    }

    public var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            updateGestureStates()
        }
    }

    public var isSingleTapEnabled: Bool = true { didSet { singleTapGR?.isEnabled = isSingleTapEnabled && _isEnabled } }
    public var isDoubleTapEnabled: Bool = true { didSet { doubleTapGR?.isEnabled = isDoubleTapEnabled && _isEnabled } }
    public var isPanEnabled: Bool = false { didSet { panGR?.isEnabled = isPanEnabled && _isEnabled } }
    public var isLongPressEnabled: Bool = true { didSet { longPressGR?.isEnabled = isLongPressEnabled && _isEnabled } }
    public var isPinchEnabled: Bool = false { didSet { pinchGR?.isEnabled = isPinchEnabled && _isEnabled } }

    public required override init() {
        super.init()
    }

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        tryBindPlayerView()

        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.tryBindPlayerView()
        }
    }

    private func tryBindPlayerView() {
        guard _gestureView == nil else { return }
        guard let engine = context?.resolveService(PlayerEngineCoreService.self),
              let pv = engine.playerView else { return }
        pv.isUserInteractionEnabled = true
        _gestureView = pv
        setupGestureRecognizers()
    }

    public func addHandler(_ handler: PlayerGestureHandler) {
        var list = handlers[handler.gestureType] ?? []
        guard !list.contains(where: { $0 === handler }) else { return }
        list.append(handler)
        handlers[handler.gestureType] = list
    }

    public func removeHandler(_ handler: PlayerGestureHandler) {
        handlers[handler.gestureType]?.removeAll { $0 === handler }
    }

    public func disableGesture(_ type: PlayerGestureType, forScene scene: String) {
        var set = disabledGestures[scene] ?? []
        set.insert(type)
        disabledGestures[scene] = set
    }

    public func enableGesture(_ type: PlayerGestureType, forScene scene: String) {
        disabledGestures[scene]?.remove(type)
    }

    private func isGestureDisabled(_ type: PlayerGestureType) -> Bool {
        for (_, set) in disabledGestures {
            if set.contains(type) { return true }
        }
        return false
    }

    private func setupGestureRecognizers() {
        guard let view = _gestureView else { return }

        let single = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        single.numberOfTapsRequired = 1
        view.addGestureRecognizer(single)
        singleTapGR = single

        let double = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        double.numberOfTapsRequired = 2
        view.addGestureRecognizer(double)
        doubleTapGR = double

        single.require(toFail: double)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        panGR = pan

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        pinchGR = pinch

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPress)
        longPressGR = longPress

        updateGestureStates()
    }

    private func removeAllGestureRecognizers() {
        if let gr = singleTapGR { _gestureView?.removeGestureRecognizer(gr) }
        if let gr = doubleTapGR { _gestureView?.removeGestureRecognizer(gr) }
        if let gr = panGR { _gestureView?.removeGestureRecognizer(gr) }
        if let gr = pinchGR { _gestureView?.removeGestureRecognizer(gr) }
        if let gr = longPressGR { _gestureView?.removeGestureRecognizer(gr) }
        singleTapGR = nil
        doubleTapGR = nil
        panGR = nil
        pinchGR = nil
        longPressGR = nil
    }

    private func updateGestureStates() {
        singleTapGR?.isEnabled = _isEnabled && isSingleTapEnabled
        doubleTapGR?.isEnabled = _isEnabled && isDoubleTapEnabled
        panGR?.isEnabled = _isEnabled && isPanEnabled
        pinchGR?.isEnabled = _isEnabled && isPinchEnabled
        longPressGR?.isEnabled = _isEnabled && isLongPressEnabled
    }

    @objc private func handleSingleTap(_ gr: UITapGestureRecognizer) {
        guard !isGestureDisabled(.singleTap) else { return }
        dispatchHandlers(type: .singleTap, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureSingleTap, object: nil, sender: self)
    }

    @objc private func handleDoubleTap(_ gr: UITapGestureRecognizer) {
        guard !isGestureDisabled(.doubleTap) else { return }
        dispatchHandlers(type: .doubleTap, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureDoubleTap, object: nil, sender: self)
    }

    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard !isGestureDisabled(.pan) else { return }
        let direction = detectPanDirection(gr)
        dispatchHandlers(type: .pan, recognizer: gr, direction: direction)
        context?.post(.playerGesturePan, object: direction as AnyObject, sender: self)
    }

    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard !isGestureDisabled(.pinch) else { return }
        dispatchHandlers(type: .pinch, recognizer: gr, direction: .unknown)
        context?.post(.playerGesturePinch, object: nil, sender: self)
    }

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard !isGestureDisabled(.longPress) else { return }
        dispatchHandlers(type: .longPress, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureLongPress, object: gr.state.rawValue, sender: self)
    }

    private func dispatchHandlers(type: PlayerGestureType, recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let list = handlers[type] else { return }
        for handler in list {
            handler.handleGesture(recognizer, direction: direction)
        }
    }

    private func detectPanDirection(_ gr: UIPanGestureRecognizer) -> PlayerPanDirection {
        guard gr.state == .began || gr.state == .changed else { return .unknown }
        let velocity = gr.velocity(in: _gestureView)
        if abs(velocity.x) > abs(velocity.y) {
            return .horizontal
        } else {
            guard let view = _gestureView else { return .unknown }
            let location = gr.location(in: view)
            return location.x < view.bounds.midX ? .verticalLeft : .verticalRight
        }
    }
}
