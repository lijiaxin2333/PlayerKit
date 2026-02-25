import UIKit
import PlayerKit

@MainActor
public final class ShowcaseFeedPreRenderPlugin: BasePlugin, ShowcaseFeedPreRenderService {

    private var consumePreRendered: ((String) -> Player?)?
    private var cancelPreRenderFn: ((String) -> Void)?

    @PlayerPlugin private var cellViewService: ShowcaseFeedCellViewService?
    @PlayerPlugin private var dataService: ShowcaseFeedDataService?

    private var playerContainerView: UIView? {
        cellViewService?.playerContainerView
    }

    private var sceneContext: ShowcaseFeedScenePlayer? {
        (context as? Context)?.holder as? ShowcaseFeedScenePlayer
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        context.add(self, event: .cellWillDisplay) { [weak self] _, _ in
            self?.attachPrerenderPlayerView()
        }

        context.add(self, event: .cellDidEndDisplaying) { [weak self] _, _ in
            self?.removePrerenderPlayerView()
        }

        context.add(self, event: .cellPrepareForReuse) { [weak self] _, _ in
            self?.removePrerenderPlayerView()
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseFeedPreRenderConfigModel else { return }
        consumePreRendered = model.consumePreRendered
        cancelPreRenderFn = model.cancelPreRender
    }

    public func attachPrerenderPlayerView() {
        guard let index = dataService?.videoIndex, index >= 0 else { return }
        guard let sceneCtx = sceneContext else { return }
        guard let container = playerContainerView else { return }
        let hasPlayerView = container.subviews.contains(where: { $0 is PlayerEngineRenderView })
        guard !hasPlayerView else { return }

        guard let player = sceneCtx.player else { return }

        // 已有引擎且有内容，直接挂载视图
        if player.engineService?.avPlayer?.currentItem != nil {
            attachPlayerViewToContainer(player)
            return
        }

        // 尝试消费预渲染引擎（滑动过程中展示首帧）
        guard let video = dataService?.video else { return }
        let identifier = video.feedId
        guard let consume = consumePreRendered,
              let preRenderedPlayer = consume(identifier) else { return }
        guard preRenderedPlayer.engineService?.currentURL == video.url else {
            cancelPreRenderFn?(identifier)
            return
        }

        player.bindPool(identifier: "showcase")
        player.adoptEngine(from: preRenderedPlayer)
        // 预渲染引擎的 isLooping=true，正式播放需要恢复为 false
        player.engineService?.isLooping = false
        attachPlayerViewToContainer(player)
    }

    public func removePrerenderPlayerView() {
        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
    }

    private func attachPlayerViewToContainer(_ player: Player) {
        guard let container = playerContainerView else { return }
        guard let pv = player.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        container.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: container.topAnchor),
            pv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        if let renderView = pv as? PlayerEngineRenderView {
            renderView.ensurePlayerBound()
        }
    }
}
