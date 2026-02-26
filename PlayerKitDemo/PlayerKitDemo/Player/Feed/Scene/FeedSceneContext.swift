import Foundation
import UIKit
import PlayerKit

public class FeedSceneConfiguration {

    public var pluginBlackList: Set<String> = []

    public var autoPlay: Bool = true

    public init() {}
}

@MainActor
final class FeedSceneRegProvider: RegisterProvider {

    private let scenePlayerRegProvider = ScenePlayerRegProvider()

    func registerPlugins(with registerSet: PluginRegisterSet) {
        // 场景层 UI 插件
        scenePlayerRegProvider.registerPlugins(with: registerSet)

        // 场景播放流程
        registerSet.addEntry(pluginClass: ScenePlayerProcessPlugin.self,
                            serviceType: ScenePlayerProcessService.self)
    }
}

@MainActor
public final class FeedSceneContext: ScenePlayerProtocol {

    public let context: PublicContext

    private var _player: Player?
    private let configuration: FeedSceneConfiguration
    private let regProvider = FeedSceneRegProvider()

    public init(configuration: FeedSceneConfiguration = FeedSceneConfiguration()) {
        self.configuration = configuration
        let ctx = Context(name: "FeedScene")
        self.context = ctx
        ctx.addRegProvider(regProvider)
    }

    // MARK: - ScenePlayerProtocol

    public var player: Player? {
        _player
    }

    public func createPlayer(prerenderKey: String?) -> Player {
        let player = Player(name: "FeedPlayer.\(UUID().uuidString)")

        // 配置引擎
        let configModel = PlayerEngineCoreConfigModel()
        configModel.autoPlay = configuration.autoPlay
        player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: configModel)

        // 配置预渲染 key
        if let key = prerenderKey {
            player.context.configPlugin(serviceProtocol: PlayerPreRenderService.self, withModel: key)
        }

        return player
    }

    public func addPlayer(_ player: Player) {
        if _player === player { return }
        removePlayer()
        _player = player
        (context as? Context)?.addSubContext(player.context)
    }

    public func removePlayer() {
        guard let player = _player else { return }
        (context as? Context)?.removeSubContext(player.context)
        _player = nil
    }

    public func hasPlayer() -> Bool {
        _player != nil
    }

    // MARK: - Convenience

    @PlayerPlugin public var sceneProcessService: ScenePlayerProcessService?
    @PlayerPlugin public var engineService: PlayerEngineCoreService?
    @PlayerPlugin public var dataService: PlayerDataService?
    @PlayerPlugin public var viewService: PlayerViewService?

    public var playerView: UIView? {
        engineService?.playerView
    }

    // MARK: - Play Control

    public func execPlay(
        prepare: (() -> Void)? = nil,
        setDataIfNeeded: (() -> Void)? = nil
    ) {
        sceneProcessService?.execPlay(
            isAutoPlay: configuration.autoPlay,
            prepare: prepare,
            attach: nil,
            checkDataValid: nil,
            setDataIfNeeded: setDataIfNeeded
        )
    }

    // MARK: - Cleanup

    public func cleanup() {
        removePlayer()
    }
}
