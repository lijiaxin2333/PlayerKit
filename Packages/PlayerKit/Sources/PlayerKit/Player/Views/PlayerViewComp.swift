import Foundation
import UIKit

public class PlayerViewConfigModel {

    public var showBackgroundColor: Bool = true
    public var backgroundColor: UIColor = .black

    public init() {}
}

@MainActor
public final class PlayerViewComp: CCLBaseComp, PlayerViewService {

    public typealias ConfigModelType = PlayerViewConfigModel

    public static let cclServiceName = "PlayerViewService"

    private var config: PlayerViewConfigModel = PlayerViewConfigModel()

    public private(set) var actionView: PlayerActionView?
    public private(set) var backgroundColorView: UIView?
    public private(set) var controlUnderlayView: UIView?
    public private(set) var controlView: UIView?
    public private(set) var controlOverlayView: UIView?

    private weak var containerPlayerView: PlayerContainerView?

    public var containerView: UIView {
        return containerPlayerView?.containerView ?? actionView ?? UIView()
    }

    public required override init() {
        self.config = PlayerViewConfigModel()
        super.init()
    }

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.trySetupFromEngine()
        }
    }

    private func trySetupFromEngine() {
        guard actionView == nil else { return }
        guard let engine = context?.resolveService(PlayerEngineCoreService.self) else { return }
        guard let pv = engine.playerView else { return }

        let av = PlayerActionView()
        av.backgroundColor = .clear
        av.translatesAutoresizingMaskIntoConstraints = false
        self.actionView = av

        let bgView = createLayerView(color: config.backgroundColor)
        let underlayView = createLayerView()
        let ctrlView = createLayerView()
        let overlayView = createLayerView()

        self.backgroundColorView = bgView
        self.controlUnderlayView = underlayView
        self.controlView = ctrlView
        self.controlOverlayView = overlayView

        av.addSubview(bgView, viewType: .backgroundColorView)
        av.addSubview(underlayView, viewType: .controlUnderlayView)
        av.addSubview(ctrlView, viewType: .controlView)
        av.addSubview(overlayView, viewType: .controlOverlayView)

        for layerView in [bgView, underlayView, ctrlView, overlayView] {
            NSLayoutConstraint.activate([
                layerView.topAnchor.constraint(equalTo: av.topAnchor),
                layerView.leadingAnchor.constraint(equalTo: av.leadingAnchor),
                layerView.trailingAnchor.constraint(equalTo: av.trailingAnchor),
                layerView.bottomAnchor.constraint(equalTo: av.bottomAnchor)
            ])
        }
    }

    public func setup(with containerView: PlayerContainerView) {
        self.containerPlayerView = containerView
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerViewConfigModel else { return }

        self.config = configModel
        applyConfig(configModel)
    }

    private func createLayerView(color: UIColor = .clear) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    private func applyConfig(_ config: PlayerViewConfigModel) {
        backgroundColorView?.backgroundColor = config.backgroundColor
    }

    public func addSubview(_ view: UIView, viewType: PlayerViewType) {
        actionView?.addSubview(view, viewType: viewType)
    }

    public func addSubViewBelowEngineView(_ view: UIView, viewType: PlayerViewType) {
        if viewType == .backgroundColorView, let bgView = backgroundColorView {
            bgView.addSubview(view)
            view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: bgView.topAnchor),
                view.leadingAnchor.constraint(equalTo: bgView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: bgView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: bgView.bottomAnchor)
            ])
        } else {
            addSubview(view, viewType: viewType)
        }
    }
}
