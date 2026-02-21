import UIKit
import PlayerKit

public extension Event {
    static let showcaseFeedDataDidUpdate: Event = "ShowcaseFeedDataDidUpdate"
    static let showcaseFeedCellViewDidSet: Event = "ShowcaseFeedCellViewDidSet"
    static let showcaseFeedCellViewDidSetSticky: Event = "ShowcaseFeedCellViewDidSetSticky"
    static let cellPrepareForReuse: Event = "CellPrepareForReuse"
    static let cellWillDisplay: Event = "CellWillDisplay"
    static let cellDidEndDisplaying: Event = "CellDidEndDisplaying"
    static let showcaseOverlayDidTapLike: Event = "ShowcaseOverlayDidTapLike"
    static let showcaseOverlayDidTapComment: Event = "ShowcaseOverlayDidTapComment"
    static let showcaseOverlayDidTapShare: Event = "ShowcaseOverlayDidTapShare"
    static let showcaseOverlayDidTapAvatar: Event = "ShowcaseOverlayDidTapAvatar"
    static let showcaseOverlayDidTapDetail: Event = "ShowcaseOverlayDidTapDetail"
    static let showcaseAutoPlayNextRequest: Event = "ShowcaseAutoPlayNextRequest"
}

@MainActor
final class ShowcaseFeedSceneRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        registerSet.addEntry(pluginClass: PlayerTypedPlayerLayeredPlugin.self, serviceType: PlayerTypedPlayerLayeredService.self)
        registerSet.addEntry(pluginClass: PlayerScenePlayerProcessPlugin.self, serviceType: PlayerScenePlayerProcessService.self)
        registerSet.addEntry(pluginClass: ShowcaseFeedDataPlugin.self, serviceType: ShowcaseFeedDataService.self)
        registerSet.addEntry(pluginClass: ShowcaseFeedCellViewPlugin.self, serviceType: ShowcaseFeedCellViewService.self)
        registerSet.addEntry(pluginClass: ShowcaseFeedOverlayPlugin.self, serviceType: ShowcaseFeedOverlayService.self)
        registerSet.addEntry(pluginClass: ShowcaseAutoPlayNextPlugin.self, serviceType: ShowcaseAutoPlayNextService.self)
        registerSet.addEntry(pluginClass: ShowcaseFeedPreRenderPlugin.self, serviceType: ShowcaseFeedPreRenderService.self)
    }
}

@MainActor
final class ShowcaseFeedScenePlayer: ScenePlayerProtocol {

    let context: PublicContext
    private var _typedPlayer: FeedPlayer?
    private let regProvider = ShowcaseFeedSceneRegProvider()

    var dataService: ShowcaseFeedDataService? {
        context.resolveService(ShowcaseFeedDataService.self)
    }

    var cellViewService: ShowcaseFeedCellViewService? {
        context.resolveService(ShowcaseFeedCellViewService.self)
    }

    init() {
        let ctx = Context(name: "ShowcaseFeedSceneContext")
        self.context = ctx
        ctx.holder = self
        ctx.addRegProvider(regProvider)
        let typedPlayer = createTypedPlayer(prerenderKey: nil)
        addTypedPlayer(typedPlayer)
    }

    // MARK: - PlayerScenePlayerProtocol

    var typedPlayer: (any TypedPlayerProtocol)? {
        _typedPlayer
    }

    func createTypedPlayer(prerenderKey: String?) -> any TypedPlayerProtocol {
        let config = FeedPlayerConfiguration()
        config.prerenderKey = prerenderKey
        return FeedPlayer(configuration: config)
    }

    func addTypedPlayer(_ typedPlayer: any TypedPlayerProtocol) {
        guard let feedPlayer = typedPlayer as? FeedPlayer else { return }
        if _typedPlayer === feedPlayer { return }
        removeTypedPlayer()
        _typedPlayer = feedPlayer
        context.addSubContext(feedPlayer.context)
    }

    func removeTypedPlayer() {
        guard let feedPlayer = _typedPlayer else { return }
        context.removeSubContext(feedPlayer.context)
        _typedPlayer = nil
    }

    func hasTypedPlayer() -> Bool {
        _typedPlayer != nil
    }

    // MARK: - Convenience

    var feedPlayer: FeedPlayer? { _typedPlayer }

    var engineService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    var playerView: UIView? {
        engineService?.playerView
    }
}
