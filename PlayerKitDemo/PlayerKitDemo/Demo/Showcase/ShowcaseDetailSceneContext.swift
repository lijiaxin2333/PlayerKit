import UIKit
import PlayerKit

@MainActor
final class ShowcaseDetailRegProvider: RegisterProvider {

    func registerPlugins(with registerSet: PluginRegisterSet) {
        registerSet.addEntry(
            pluginClass: ShowcaseDetailControlPlugin.self,
            serviceType: ShowcaseDetailControlService.self
        )
        registerSet.addEntry(
            pluginClass: ShowcaseDetailLongPressSpeedPlugin.self,
            serviceType: ShowcaseDetailLongPressSpeedService.self
        )
    }
}

@MainActor
final class ShowcaseDetailSceneBaseRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        registerSet.addEntry(pluginClass: PlayerTypedPlayerLayeredPlugin.self, serviceType: PlayerTypedPlayerLayeredService.self)
    }
}

@MainActor
final class ShowcaseDetailSceneContext: ContextHolder {

    let context: PublicContext
    private let baseRegProvider = ShowcaseDetailSceneBaseRegProvider()
    private let regProvider = ShowcaseDetailRegProvider()
    private weak var _feedPlayer: FeedPlayer?

    private static let detailBlacklist: Set<String> = [String(reflecting: PlayerSpeedPanelService.self)]

    init() {
        let ctx = Context(name: "ShowcaseDetailSceneContext")
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
