import UIKit

/** UIView 字符串标签关联键 */
private var stringTagKey: UInt8 = 0

public extension UIView {

    /** 视图的字符串标签，用于标识视图层级类型 */
    var ttv_stringTag: String? {
        get {
            return objc_getAssociatedObject(self, &stringTagKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &stringTagKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

/** 触摸忽略视图，自身不接收触摸事件但子视图可以 */
@MainActor
public final class PlayerTouchIgnoringView: UIView {

    /** 命中测试，如果命中自身则返回 nil 以忽略触摸 */
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, with: event)
        if hitTestView == self {
            return nil
        }
        return hitTestView
    }
}

/** 播放器容器视图，包含手势层、内容层和控制层三个子层 */
@MainActor
public final class PlayerContainerView: UIView {

    /** 手势响应视图层 */
    public let gestureView: PlayerTouchIgnoringView
    /** 视频内容容器层 */
    public let containerView: UIView
    /** 播控 UI 层 */
    public let controlView: PlayerTouchIgnoringView

    /** 使用 frame 初始化容器视图 */
    public override init(frame: CGRect) {
        gestureView = PlayerTouchIgnoringView()
        gestureView.backgroundColor = .clear
        gestureView.translatesAutoresizingMaskIntoConstraints = false

        containerView = UIView()
        containerView.backgroundColor = .black
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true

        controlView = PlayerTouchIgnoringView()
        controlView.backgroundColor = .clear
        controlView.translatesAutoresizingMaskIntoConstraints = false

        super.init(frame: frame)
        setupView()
    }

    /** 使用 NSCoder 初始化容器视图 */
    public required init?(coder: NSCoder) {
        gestureView = PlayerTouchIgnoringView()
        gestureView.backgroundColor = .clear
        gestureView.translatesAutoresizingMaskIntoConstraints = false

        containerView = UIView()
        containerView.backgroundColor = .black
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.clipsToBounds = true

        controlView = PlayerTouchIgnoringView()
        controlView.backgroundColor = .clear
        controlView.translatesAutoresizingMaskIntoConstraints = false

        super.init(coder: coder)
        setupView()
    }

    /** 配置子视图布局约束 */
    private func setupView() {
        addSubview(gestureView)
        addSubview(containerView)
        addSubview(controlView)

        NSLayoutConstraint.activate([
            gestureView.topAnchor.constraint(equalTo: topAnchor),
            gestureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            gestureView.trailingAnchor.constraint(equalTo: trailingAnchor),
            gestureView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        gestureView.isUserInteractionEnabled = false
    }

    /** 是否允许滚动穿透，启用时禁止自身用户交互 */
    public var scrollPassthroughEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = !scrollPassthroughEnabled
        }
    }

    /** 添加子视图到指定视图层级 */
    public func addSubview(_ view: UIView, toLayer viewType: PlayerViewType) {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.ttv_stringTag = viewType.rawValue

        switch viewType {
        case .gestureView:
            gestureView.addSubview(view)
            bringSubviewToFront(gestureView)
        case .containerView:
            containerView.addSubview(view)
            bringSubviewToFront(containerView)
        case .controlView:
            controlView.addSubview(view)
            bringSubviewToFront(controlView)
        default:
            controlView.addSubview(view)
        }
    }

    /** 获取指定类型的视图 */
    public func view(for viewType: PlayerViewType) -> UIView? {
        switch viewType {
        case .gestureView:
            return gestureView
        case .containerView:
            return containerView
        case .controlView:
            return controlView
        default:
            return controlView.subviews.first { $0.ttv_stringTag == viewType.rawValue }
        }
    }

    /** 是否启用手势交互 */
    public var isGestureEnabled: Bool = true {
        didSet {
            gestureView.isUserInteractionEnabled = isGestureEnabled
        }
    }

    /** 是否显示播控 UI */
    public var isControlVisible: Bool = true {
        didSet {
            controlView.isHidden = !isControlVisible
        }
    }

    /** 布局就绪回调，首次有效布局时触发 */
    public var onLayoutReady: (() -> Void)?

    /** 布局子视图时检查并触发布局就绪回调 */
    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            onLayoutReady?()
            onLayoutReady = nil
        }
    }
}
