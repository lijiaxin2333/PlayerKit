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
        registerSet.addEntry(pluginClass: PlayerPlayerLayeredPlugin.self, serviceType: PlayerPlayerLayeredService.self)
    }
}

@MainActor
final class ShowcaseDetailSceneContext: ContextHolder {

    let context: PublicContext
    private let baseRegProvider = ShowcaseDetailSceneBaseRegProvider()
    private let regProvider = ShowcaseDetailRegProvider()
    private weak var _player: Player?

    private static let detailBlacklist: Set<String> = [String(reflecting: PlayerSpeedPanelService.self)]

    init() {
        let ctx = Context(name: "ShowcaseDetailSceneContext")
        self.context = ctx
        ctx.holder = self
        ctx.addRegProvider(baseRegProvider)
    }

    func addPlayer(_ player: Player) {
        if _player === player { return }
        removePlayer()
        _player = player

        player.context.updateRegistryBlacklist(Self.detailBlacklist)
        context.addSubContext(player.context)
        context.addRegProvider(regProvider)
    }

    func removePlayer() {
        guard let player = _player else { return }
        context.removeRegProvider(regProvider)
        player.context.updateRegistryBlacklist(nil)
        context.removeSubContext(player.context)
        _player = nil
    }

    var player: Player? { _player }
}
