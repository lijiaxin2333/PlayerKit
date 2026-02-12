import UIKit

public extension CCLEvent {
    static let showcaseFeedDataDidUpdate: CCLEvent = "ShowcaseFeedDataDidUpdate"
    static let showcaseFeedDataWillUpdate: CCLEvent = "ShowcaseFeedDataWillUpdate"
    static let showcaseFeedCellViewDidSet: CCLEvent = "ShowcaseFeedCellViewDidSet"
    static let showcaseFeedCellViewDidSetSticky: CCLEvent = "ShowcaseFeedCellViewDidSetSticky"
    static let cellPrepareForReuse: CCLEvent = "CellPrepareForReuse"
    static let cellWillDisplay: CCLEvent = "CellWillDisplay"
    static let cellDidEndDisplaying: CCLEvent = "CellDidEndDisplaying"
    static let showcaseOverlayDidTapLike: CCLEvent = "ShowcaseOverlayDidTapLike"
    static let showcaseOverlayDidTapComment: CCLEvent = "ShowcaseOverlayDidTapComment"
    static let showcaseOverlayDidTapShare: CCLEvent = "ShowcaseOverlayDidTapShare"
    static let showcaseOverlayDidTapAvatar: CCLEvent = "ShowcaseOverlayDidTapAvatar"
    static let showcaseOverlayDidTapDetail: CCLEvent = "ShowcaseOverlayDidTapDetail"
    static let showcaseAutoPlayNextRequest: CCLEvent = "ShowcaseAutoPlayNextRequest"
}

@MainActor
final class ShowcaseFeedSceneRegProvider: CCLRegisterProvider {
    func registerComps(with registerSet: CCLCompRegisterSet) {
        registerSet.addEntry(compClass: PlayerTypedPlayerLayeredComp.self, serviceType: PlayerTypedPlayerLayeredService.self)
        registerSet.addEntry(compClass: PlayerScenePlayerProcessComp.self, serviceType: PlayerScenePlayerProcessService.self)
        registerSet.addEntry(compClass: ShowcaseFeedDataComp.self, serviceType: ShowcaseFeedDataService.self)
        registerSet.addEntry(compClass: ShowcaseFeedCellViewComp.self, serviceType: ShowcaseFeedCellViewService.self)
        registerSet.addEntry(compClass: ShowcaseFeedOverlayComp.self, serviceType: ShowcaseFeedOverlayService.self)
        registerSet.addEntry(compClass: ShowcaseAutoPlayNextComp.self, serviceType: ShowcaseAutoPlayNextService.self)
        registerSet.addEntry(compClass: ShowcaseFeedPreRenderComp.self, serviceType: ShowcaseFeedPreRenderService.self)
    }
}

@MainActor
final class ShowcaseFeedSceneContext: ScenePlayerProtocol {

    let context: CCLPublicContext
    private var _typedPlayer: FeedPlayer?
    private let regProvider = ShowcaseFeedSceneRegProvider()

    var dataService: ShowcaseFeedDataService? {
        context.resolveService(ShowcaseFeedDataService.self)
    }

    var cellViewService: ShowcaseFeedCellViewService? {
        context.resolveService(ShowcaseFeedCellViewService.self)
    }

    init() {
        let ctx = CCLContext(name: "ShowcaseFeedSceneContext")
        self.context = ctx
        ctx.holder = self
        ctx.addRegProvider(regProvider)
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

// MARK: - Context Forwarding

@MainActor
extension ShowcaseFeedSceneContext {

    func post(_ event: CCLEvent, object: Any? = nil, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        context.add(observer, event: event, handler: handler)
    }

    func configComp<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        context.configComp(serviceProtocol: serviceProtocol, withModel: configModel)
    }
}
