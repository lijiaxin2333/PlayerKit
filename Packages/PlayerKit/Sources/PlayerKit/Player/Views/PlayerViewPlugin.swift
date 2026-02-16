import Foundation
import UIKit

/** 播放器视图配置模型 */
public class PlayerViewConfigModel {

    /** 是否显示背景色 */
    public var showBackgroundColor: Bool = true
    /** 背景颜色 */
    public var backgroundColor: UIColor = .black

    /** 初始化视图配置模型 */
    public init() {}
}

/** 播放器视图插件，管理播放器的视图层级结构 */
@MainActor
public final class PlayerViewPlugin: BasePlugin, PlayerViewService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerViewConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerViewService"

    /** 视图配置 */
    private var config: PlayerViewConfigModel = PlayerViewConfigModel()

    /** 交互视图（ActionView） */
    public private(set) var actionView: PlayerActionView?
    /** 背景色视图 */
    public private(set) var backgroundColorView: UIView?
    /** 播控下层视图 */
    public private(set) var controlUnderlayView: UIView?
    /** 播控视图 */
    public private(set) var controlView: UIView?
    /** 播控上层视图 */
    public private(set) var controlOverlayView: UIView?

    /** 容器播放器视图弱引用 */
    private weak var containerPlayerView: PlayerContainerView?

    /** 视图容器，优先返回 containerPlayerView 的容器 */
    public var containerView: UIView {
        return containerPlayerView?.containerView ?? actionView ?? UIView()
    }

    /** 必须的初始化方法 */
    public required override init() {
        self.config = PlayerViewConfigModel()
        super.init()
    }

    /** 插件加载完成，监听引擎创建事件以初始化视图 */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.trySetupFromEngine()
        }
    }

    /** 尝试从引擎获取视图并构建视图层级 */
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

    /** 设置容器视图 */
    public func setup(with containerView: PlayerContainerView) {
        self.containerPlayerView = containerView
    }

    /** 配置插件，应用视图配置 */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerViewConfigModel else { return }

        self.config = configModel
        applyConfig(configModel)
    }

    /** 创建一个层级视图 */
    private func createLayerView(color: UIColor = .clear) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }

    /** 应用配置到视图 */
    private func applyConfig(_ config: PlayerViewConfigModel) {
        backgroundColorView?.backgroundColor = config.backgroundColor
    }

    /** 添加子视图到指定层级 */
    public func addSubview(_ view: UIView, viewType: PlayerViewType) {
        actionView?.addSubview(view, viewType: viewType)
    }

    /** 添加子视图到引擎视图下方 */
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
