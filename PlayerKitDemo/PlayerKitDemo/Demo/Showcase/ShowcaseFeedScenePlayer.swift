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
        registerSet.addEntry(pluginClass: PlayerPlayerLayeredPlugin.self, serviceType: PlayerPlayerLayeredService.self)
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
    private var _player: Player?
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
    }

    // MARK: - ScenePlayerProtocol

    var player: Player? {
        _player
    }

    func createPlayer(prerenderKey: String?) -> Player {
        let player = Player(name: "ShowcaseFeedPlayer.\(UUID().uuidString)")

        // 配置引擎
        let configModel = PlayerEngineCoreConfigModel()
        configModel.autoPlay = true
        configModel.isLooping = false
        player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: configModel)

        // 配置预渲染 key
        if let key = prerenderKey {
            player.context.configPlugin(serviceProtocol: PlayerPreRenderService.self, withModel: key)
        }

        return player
    }

    func addPlayer(_ player: Player) {
        if _player === player { return }
        removePlayer()
        _player = player
        context.addSubContext(player.context)
    }

    func removePlayer() {
        guard let player = _player else { return }
        context.removeSubContext(player.context)
        _player = nil
    }

    func hasPlayer() -> Bool {
        _player != nil
    }

    // MARK: - Convenience

    var engineService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    var playerView: UIView? {
        engineService?.playerView
    }
}
