import Foundation
import UIKit

/**
 * 播放器手势插件，负责管理各种手势识别及分发
 */
@MainActor
public final class PlayerGesturePlugin: BasePlugin, PlayerGestureService {

    /** 各类型手势对应的处理器列表 */
    private var handlers: [PlayerGestureType: [PlayerGestureHandler]] = [:]
    /** 按场景禁用的手势集合 */
    private var disabledGestures: [String: Set<PlayerGestureType>] = [:]

    /** 单击手势识别器 */
    private var singleTapGR: UITapGestureRecognizer?
    /** 双击手势识别器 */
    private var doubleTapGR: UITapGestureRecognizer?
    /** 滑动手势识别器 */
    private var panGR: UIPanGestureRecognizer?
    /** 捏合手势识别器 */
    private var pinchGR: UIPinchGestureRecognizer?
    /** 长按手势识别器 */
    private var longPressGR: UILongPressGestureRecognizer?

    /** 手势承载视图弱引用 */
    private weak var _gestureView: UIView?
    /** 手势是否启用 */
    private var _isEnabled: Bool = true

    /** 是否为外部传入的手势视图 */
    private var _isExternalGestureView: Bool = false

    /**
     * 手势承载视图，设置后在该视图上添加手势；为 nil 时自动绑定播放器视图
     */
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

    /**
     * 重新绑定到播放器视图
     */
    private func rebindPlayerView() {
        guard let engine = context?.resolveService(PlayerEngineCoreService.self),
              let pv = engine.playerView else { return }
        pv.isUserInteractionEnabled = true
        _gestureView = pv
        setupGestureRecognizers()
    }

    /**
     * 是否启用所有手势
     */
    public var isEnabled: Bool {
        get { _isEnabled }
        set {
            _isEnabled = newValue
            updateGestureStates()
        }
    }

    /** 是否启用单击 */
    public var isSingleTapEnabled: Bool = true { didSet { singleTapGR?.isEnabled = isSingleTapEnabled && _isEnabled } }
    /** 是否启用双击 */
    public var isDoubleTapEnabled: Bool = true { didSet { doubleTapGR?.isEnabled = isDoubleTapEnabled && _isEnabled } }
    /** 是否启用滑动 */
    public var isPanEnabled: Bool = false { didSet { panGR?.isEnabled = isPanEnabled && _isEnabled } }
    /** 是否启用长按 */
    public var isLongPressEnabled: Bool = true { didSet { longPressGR?.isEnabled = isLongPressEnabled && _isEnabled } }
    /** 是否启用捏合 */
    public var isPinchEnabled: Bool = false { didSet { pinchGR?.isEnabled = isPinchEnabled && _isEnabled } }

    /**
     * 初始化
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成，绑定播放器视图并监听引擎创建事件
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        tryBindPlayerView()

        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.tryBindPlayerView()
        }
    }

    /**
     * 尝试绑定播放器视图
     */
    private func tryBindPlayerView() {
        guard _gestureView == nil else { return }
        guard let engine = context?.resolveService(PlayerEngineCoreService.self),
              let pv = engine.playerView else { return }
        pv.isUserInteractionEnabled = true
        _gestureView = pv
        setupGestureRecognizers()
    }

    /**
     * 添加手势处理器
     */
    public func addHandler(_ handler: PlayerGestureHandler) {
        var list = handlers[handler.gestureType] ?? []
        guard !list.contains(where: { $0 === handler }) else { return }
        list.append(handler)
        handlers[handler.gestureType] = list
    }

    /**
     * 移除手势处理器
     */
    public func removeHandler(_ handler: PlayerGestureHandler) {
        handlers[handler.gestureType]?.removeAll { $0 === handler }
    }

    /**
     * 在指定场景下禁用某类手势
     */
    public func disableGesture(_ type: PlayerGestureType, forScene scene: String) {
        var set = disabledGestures[scene] ?? []
        set.insert(type)
        disabledGestures[scene] = set
    }

    /**
     * 在指定场景下启用某类手势
     */
    public func enableGesture(_ type: PlayerGestureType, forScene scene: String) {
        disabledGestures[scene]?.remove(type)
    }

    /**
     * 判断某类手势是否被禁用
     */
    private func isGestureDisabled(_ type: PlayerGestureType) -> Bool {
        for (_, set) in disabledGestures {
            if set.contains(type) { return true }
        }
        return false
    }

    /**
     * 配置所有手势识别器
     */
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

    /**
     * 移除所有手势识别器
     */
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

    /**
     * 更新各手势启用状态
     */
    private func updateGestureStates() {
        singleTapGR?.isEnabled = _isEnabled && isSingleTapEnabled
        doubleTapGR?.isEnabled = _isEnabled && isDoubleTapEnabled
        panGR?.isEnabled = _isEnabled && isPanEnabled
        pinchGR?.isEnabled = _isEnabled && isPinchEnabled
        longPressGR?.isEnabled = _isEnabled && isLongPressEnabled
    }

    /**
     * 处理单击手势
     */
    @objc private func handleSingleTap(_ gr: UITapGestureRecognizer) {
        guard !isGestureDisabled(.singleTap) else { return }
        dispatchHandlers(type: .singleTap, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureSingleTap, object: nil, sender: self)
    }

    /**
     * 处理双击手势
     */
    @objc private func handleDoubleTap(_ gr: UITapGestureRecognizer) {
        guard !isGestureDisabled(.doubleTap) else { return }
        dispatchHandlers(type: .doubleTap, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureDoubleTap, object: nil, sender: self)
    }

    /**
     * 处理滑动手势
     */
    @objc private func handlePan(_ gr: UIPanGestureRecognizer) {
        guard !isGestureDisabled(.pan) else { return }
        let direction = detectPanDirection(gr)
        dispatchHandlers(type: .pan, recognizer: gr, direction: direction)
        context?.post(.playerGesturePan, object: direction as AnyObject, sender: self)
    }

    /**
     * 处理捏合手势
     */
    @objc private func handlePinch(_ gr: UIPinchGestureRecognizer) {
        guard !isGestureDisabled(.pinch) else { return }
        dispatchHandlers(type: .pinch, recognizer: gr, direction: .unknown)
        context?.post(.playerGesturePinch, object: nil, sender: self)
    }

    /**
     * 处理长按手势
     */
    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        guard !isGestureDisabled(.longPress) else { return }
        dispatchHandlers(type: .longPress, recognizer: gr, direction: .unknown)
        context?.post(.playerGestureLongPress, object: gr.state.rawValue, sender: self)
    }

    /**
     * 向该类型的手势处理器分发手势事件
     */
    private func dispatchHandlers(type: PlayerGestureType, recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let list = handlers[type] else { return }
        for handler in list {
            handler.handleGesture(recognizer, direction: direction)
        }
    }

    /**
     * 检测滑动手势方向
     */
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
