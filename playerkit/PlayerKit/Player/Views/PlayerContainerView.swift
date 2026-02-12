import UIKit

private var stringTagKey: UInt8 = 0

public extension UIView {

    var ttv_stringTag: String? {
        get {
            return objc_getAssociatedObject(self, &stringTagKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &stringTagKey, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
}

@MainActor
public final class PlayerTouchIgnoringView: UIView {

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitTestView = super.hitTest(point, with: event)
        if hitTestView == self {
            return nil
        }
        return hitTestView
    }
}

@MainActor
public final class PlayerContainerView: UIView {

    public let gestureView: PlayerTouchIgnoringView
    public let containerView: UIView
    public let controlView: PlayerTouchIgnoringView

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

    public var scrollPassthroughEnabled: Bool = true {
        didSet {
            isUserInteractionEnabled = !scrollPassthroughEnabled
        }
    }

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

    public var isGestureEnabled: Bool = true {
        didSet {
            gestureView.isUserInteractionEnabled = isGestureEnabled
        }
    }

    public var isControlVisible: Bool = true {
        didSet {
            controlView.isHidden = !isControlVisible
        }
    }

    public var onLayoutReady: (() -> Void)?

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 {
            onLayoutReady?()
            onLayoutReady = nil
        }
    }
}
