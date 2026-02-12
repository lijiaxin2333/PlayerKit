import Foundation
import UIKit

public class FeedSceneConfiguration {

    public var compBlackList: Set<String> = []

    public var autoPlay: Bool = true

    public init() {}
}

@MainActor
final class FeedSceneRegProvider: CCLRegisterProvider {
    func registerComps(with registerSet: CCLCompRegisterSet) {
        registerSet.addEntry(compClass: PlayerTypedPlayerLayeredComp.self, serviceType: PlayerTypedPlayerLayeredService.self)
        registerSet.addEntry(compClass: PlayerScenePlayerProcessComp.self, serviceType: PlayerScenePlayerProcessService.self)
    }
}

@MainActor
public final class FeedSceneContext: ScenePlayerProtocol {

    public let context: CCLPublicContext

    private var _typedPlayer: FeedPlayer?
    private let configuration: FeedSceneConfiguration
    private let regProvider = FeedSceneRegProvider()

    public init(configuration: FeedSceneConfiguration = FeedSceneConfiguration()) {
        self.configuration = configuration
        let ctx = CCLContext(name: "FeedScene")
        self.context = ctx
        ctx.addRegProvider(regProvider)
    }

    // MARK: - PlayerScenePlayerProtocol

    public var typedPlayer: (any TypedPlayerProtocol)? {
        _typedPlayer
    }

    public func createTypedPlayer(prerenderKey: String?) -> any TypedPlayerProtocol {
        let config = FeedPlayerConfiguration()
        config.prerenderKey = prerenderKey
        config.autoPlay = configuration.autoPlay
        let feedPlayer = FeedPlayer(configuration: config)
        return feedPlayer
    }

    public func addTypedPlayer(_ typedPlayer: any TypedPlayerProtocol) {
        guard let feedPlayer = typedPlayer as? FeedPlayer else { return }
        if _typedPlayer === feedPlayer { return }
        removeTypedPlayer()
        _typedPlayer = feedPlayer
        (context as? CCLContext)?.addSubContext(feedPlayer.context)
    }

    public func removeTypedPlayer() {
        guard let feedPlayer = _typedPlayer else { return }
        (context as? CCLContext)?.removeSubContext(feedPlayer.context)
        _typedPlayer = nil
    }

    public func hasTypedPlayer() -> Bool {
        _typedPlayer != nil
    }

    // MARK: - Convenience

    public var sceneProcessService: PlayerScenePlayerProcessService? {
        context.resolveService(PlayerScenePlayerProcessService.self)
    }

    public var typedPlayerLayeredService: PlayerTypedPlayerLayeredService? {
        context.resolveService(PlayerTypedPlayerLayeredService.self)
    }

    public var engineService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    public var dataService: PlayerDataService? {
        context.resolveService(PlayerDataService.self)
    }

    public var viewService: PlayerViewService? {
        context.resolveService(PlayerViewService.self)
    }

    public var playerView: UIView? {
        engineService?.playerView
    }

    // MARK: - Play Control

    public func execPlay(
        prepare: (() -> Void)? = nil,
        createIfNeeded: (() -> Void)? = nil,
        setDataIfNeeded: (() -> Void)? = nil
    ) {
        sceneProcessService?.execPlay(
            isAutoPlay: configuration.autoPlay,
            prepare: prepare,
            createIfNeeded: createIfNeeded ?? { [weak self] in
                guard let self = self else { return }
                let player = self.createTypedPlayer(prerenderKey: nil)
                self.addTypedPlayer(player)
            },
            attach: nil,
            checkDataValid: nil,
            setDataIfNeeded: setDataIfNeeded
        )
    }

    // MARK: - Cleanup

    public func cleanup() {
        removeTypedPlayer()
    }
}
