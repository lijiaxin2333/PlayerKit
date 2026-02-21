import UIKit
import PlayerKit

@MainActor
protocol ShowcaseFeedPreRenderService: PluginService {
    var playbackPlugin: ShowcaseFeedPlaybackPluginProtocol? { get }
    func prerenderCurrentVideo()
    func attachPrerenderPlayerView()
    func removePrerenderPlayerView()
}

@MainActor
final class ShowcaseFeedPreRenderConfigModel {
    weak var playbackPlugin: (any ShowcaseFeedPlaybackPluginProtocol)?
    init(playbackPlugin: ShowcaseFeedPlaybackPluginProtocol?) {
        self.playbackPlugin = playbackPlugin
    }
}

@MainActor
final class ShowcaseFeedPreRenderPlugin: BasePlugin, ShowcaseFeedPreRenderService {

    private(set) weak var playbackPlugin: (any ShowcaseFeedPlaybackPluginProtocol)?

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
            self?.prerenderCurrentVideo()
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
        self.playbackPlugin = model.playbackPlugin
    }

    func prerenderCurrentVideo() {
        guard let plugin = playbackPlugin else { return }
        guard let video = dataService?.video, let url = video.url else { return }
        guard let index = dataService?.videoIndex, index >= 0 else { return }

        guard sceneContext?.feedPlayer == nil else { return }
        guard plugin.typedPlayers[index] == nil else { return }

        let identifier = "showcase_\(index)"
        let state = plugin.preRenderManager.state(for: identifier)
        guard state == .idle || state == .cancelled || state == .expired || state == .failed else { return }

        plugin.preRenderManager.preRender(url: url, identifier: identifier)
    }

    func attachPrerenderPlayerView() {
        guard let plugin = playbackPlugin else { return }
        guard let index = dataService?.videoIndex, index >= 0 else { return }
        guard let sceneCtx = sceneContext else { return }
        guard sceneCtx.feedPlayer == nil else { return }

        if let existing = plugin.typedPlayers[index] {
            guard existing.playerView != nil else { return }
            sceneCtx.addTypedPlayer(existing)
            attachPlayerViewToContainer(existing)
            return
        }

        let identifier = "showcase_\(index)"
        guard let preRenderedPlayer = plugin.preRenderManager.consumePreRendered(identifier: identifier) else { return }
        let config = FeedPlayerConfiguration()
        config.autoPlay = false
        config.looping = false
        let feedPlayer = FeedPlayer(adoptingPlayer: preRenderedPlayer, configuration: config)
        feedPlayer.bindPool(plugin.enginePool, identifier: "showcase")
        plugin.restorePlayer(feedPlayer, at: index)
        sceneCtx.addTypedPlayer(feedPlayer)
        attachPlayerViewToContainer(feedPlayer)
    }

    func removePrerenderPlayerView() {
        guard let plugin = playbackPlugin else { return }
        guard let index = dataService?.videoIndex, index >= 0 else { return }
        guard let sceneCtx = sceneContext else { return }
        guard sceneCtx.feedPlayer != nil else { return }

        guard plugin.currentPlayingIndex != index else { return }

        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
        sceneCtx.removeTypedPlayer()
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
