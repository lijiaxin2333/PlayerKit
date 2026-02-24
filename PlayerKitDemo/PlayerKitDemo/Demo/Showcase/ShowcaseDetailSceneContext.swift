import UIKit
import PlayerKit

@MainActor
final class ShowcaseDetailRegProvider: RegisterProvider {

    private let scenePlayerRegProvider = ScenePlayerRegProvider()

    func registerPlugins(with registerSet: PluginRegisterSet) {
        // 场景层 UI 插件（全屏、手势、缩放等）
        scenePlayerRegProvider.registerPlugins(with: registerSet)

        // Detail 场景特有插件
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
final class ShowcaseDetailSceneContext: ContextHolder {

    let context: PublicContext
    private let regProvider = ShowcaseDetailRegProvider()
    private weak var _player: Player?

    @PlayerPlugin var gestureService: PlayerGestureService?
    @PlayerPlugin var detailControlService: ShowcaseDetailControlService?
    @PlayerPlugin var panelService: PlayerPanelService?
    @PlayerPlugin var longPressSpeedService: ShowcaseDetailLongPressSpeedService?

    private static let detailBlacklist: Set<String> = [String(reflecting: PlayerSpeedPanelService.self)]

    init() {
        let ctx = Context(name: "ShowcaseDetailSceneContext")
        self.context = ctx
        ctx.holder = self
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
