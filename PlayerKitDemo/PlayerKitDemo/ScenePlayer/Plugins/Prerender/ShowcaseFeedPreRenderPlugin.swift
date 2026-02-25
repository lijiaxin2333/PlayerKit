import UIKit
import PlayerKit

@MainActor
public final class ShowcaseFeedPreRenderPlugin: BasePlugin, ShowcaseFeedPreRenderService {

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

    public func attachPrerenderPlayerView() {
        guard let sceneCtx = sceneContext else { return }
        guard let container = playerContainerView else { return }
        let hasPlayerView = container.subviews.contains(where: { $0 is PlayerEngineRenderView })
        guard !hasPlayerView else { return }

        guard let player = sceneCtx.player else { return }

        if player.engineService?.avPlayer?.currentItem != nil {
            attachPlayerViewToContainer(player)
        }
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
