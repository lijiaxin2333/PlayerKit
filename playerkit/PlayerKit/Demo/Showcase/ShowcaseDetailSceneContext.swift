import UIKit

@MainActor
final class ShowcaseDetailRegProvider: CCLRegisterProvider {

    func registerComps(with registerSet: CCLCompRegisterSet) {
        registerSet.addEntry(
            compClass: ShowcaseDetailControlComp.self,
            serviceType: ShowcaseDetailControlService.self
        )
        registerSet.addEntry(
            compClass: ShowcaseDetailLongPressSpeedComp.self,
            serviceType: ShowcaseDetailLongPressSpeedService.self
        )
    }
}

@MainActor
final class ShowcaseDetailSceneBaseRegProvider: CCLRegisterProvider {
    func registerComps(with registerSet: CCLCompRegisterSet) {
        registerSet.addEntry(compClass: PlayerTypedPlayerLayeredComp.self, serviceType: PlayerTypedPlayerLayeredService.self)
    }
}

@MainActor
final class ShowcaseDetailSceneContext: CCLContextHolder {

    let context: CCLPublicContext
    private let baseRegProvider = ShowcaseDetailSceneBaseRegProvider()
    private let regProvider = ShowcaseDetailRegProvider()
    private weak var _feedPlayer: FeedPlayer?

    private static let detailBlacklist: Set<String> = [
        _typeName(PlayerSpeedPanelService.self, qualified: false)
    ]

    init() {
        let ctx = CCLContext(name: "ShowcaseDetailSceneContext")
        self.context = ctx
        ctx.holder = self
        ctx.addRegProvider(baseRegProvider)
    }

    func addFeedPlayer(_ feedPlayer: FeedPlayer) {
        if _feedPlayer === feedPlayer { return }
        removeFeedPlayer()
        _feedPlayer = feedPlayer

        feedPlayer.context.updateRegistryBlacklist(Self.detailBlacklist)
        context.addSubContext(feedPlayer.context)
        context.addRegProvider(regProvider)
    }

    func removeFeedPlayer() {
        guard let feedPlayer = _feedPlayer else { return }
        context.removeRegProvider(regProvider)
        feedPlayer.context.updateRegistryBlacklist(nil)
        context.removeSubContext(feedPlayer.context)
        _feedPlayer = nil
    }

    var feedPlayer: FeedPlayer? { _feedPlayer }
}
