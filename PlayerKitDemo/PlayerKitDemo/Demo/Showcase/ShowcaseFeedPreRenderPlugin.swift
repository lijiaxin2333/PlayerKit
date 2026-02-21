import UIKit
import PlayerKit

@MainActor
protocol ShowcaseFeedPreRenderService: PluginService {
    func attachPrerenderPlayerView()
    func removePrerenderPlayerView()
}

@MainActor
final class ShowcaseFeedPreRenderConfigModel {
    let consumePreRendered: (String) -> Player?
    let cancelPreRender: (String) -> Void

    init(consumePreRendered: @escaping (String) -> Player?,
         cancelPreRender: @escaping (String) -> Void) {
        self.consumePreRendered = consumePreRendered
        self.cancelPreRender = cancelPreRender
    }
}

@MainActor
final class ShowcaseFeedPreRenderPlugin: BasePlugin, ShowcaseFeedPreRenderService {

    private var consumePreRendered: ((String) -> Player?)?
    private var cancelPreRenderFn: ((String) -> Void)?

    private var playerContainerView: UIView? {
        context?.resolveService(ShowcaseFeedCellViewService.self)?.playerContainerView
    }

    private var sceneContext: ShowcaseFeedScenePlayer? {
        (context as? Context)?.holder as? ShowcaseFeedScenePlayer
    }

    private var dataService: ShowcaseFeedDataService? {
        context?.resolveService(ShowcaseFeedDataService.self)
    }

    override func pluginDidLoad(_ context: ContextProtocol) {
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

    override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseFeedPreRenderConfigModel else { return }
        consumePreRendered = model.consumePreRendered
        cancelPreRenderFn = model.cancelPreRender
    }

    func attachPrerenderPlayerView() {
        guard let index = dataService?.videoIndex, index >= 0 else { return }
        guard let sceneCtx = sceneContext else { return }
        guard let container = playerContainerView else { return }
        let hasPlayerView = container.subviews.contains(where: { $0 is PlayerEngineRenderView })
        guard !hasPlayerView else { return }

        guard let feedPlayer = sceneCtx.feedPlayer else { return }
        if feedPlayer.engineService?.avPlayer?.currentItem != nil {
            attachPlayerViewToContainer(feedPlayer)
            return
        }

        let identifier = "showcase_\(index)"
        guard let consume = consumePreRendered,
              let preRenderedPlayer = consume(identifier) else { return }
        guard let video = dataService?.video, preRenderedPlayer.engineService?.currentURL == video.url else {
            cancelPreRenderFn?(identifier)
            return
        }

        feedPlayer.bindPool(PlayerEnginePool.shared, identifier: "showcase")
        feedPlayer.adoptEngine(from: preRenderedPlayer)
        attachPlayerViewToContainer(feedPlayer)
    }

    func removePrerenderPlayerView() {
        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
    }

    private func attachPlayerViewToContainer(_ feedPlayer: FeedPlayer) {
        guard let container = playerContainerView else { return }
        guard let pv = feedPlayer.playerView else { return }
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
