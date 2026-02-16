import Foundation

/**
 * 场景迁移插件，负责在不同播放器间迁移引擎
 */
@MainActor
public final class PlayerSceneTransferPlugin: BasePlugin, PlayerSceneTransferService {

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 将引擎从源播放器迁移到目标播放器
     */
    public func transferEngine(
        from sourcePlayer: Player,
        to targetPlayer: Player,
        completion: ((Bool) -> Void)?
    ) {
        let state = captureState(from: sourcePlayer)

        guard let engine = detachEngine(from: sourcePlayer) else {
            completion?(false)
            return
        }

        sourcePlayer.context.post(.playerEngineWillTransfer, object: engine as AnyObject, sender: self)

        attachEngine(engine, to: targetPlayer)

        if let state = state {
            restoreState(state, to: targetPlayer)
        }

        targetPlayer.context.post(.playerEngineDidTransfer, object: engine as AnyObject, sender: self)

        completion?(true)
    }

    /**
     * 从播放器上分离引擎
     */
    public func detachEngine(from player: Player) -> PlayerEngineCoreService? {
        guard let comp = player.context.detachInstance(for: PlayerEngineCoreService.self) else {
            return nil
        }
        return comp as? PlayerEngineCoreService
    }

    /**
     * 将引擎附加到播放器
     */
    public func attachEngine(_ engine: PlayerEngineCoreService, to player: Player) {
        guard let comp = engine as? BasePlugin else { return }
        player.context.registerInstance(comp, protocol: PlayerEngineCoreService.self)
    }

    /**
     * 从播放器捕获迁移前的状态
     */
    public func captureState(from player: Player) -> PlayerTransferState? {
        guard let engine = player.engineService else { return nil }
        return PlayerTransferState(from: engine)
    }

    /**
     * 将状态恢复到目标播放器的引擎
     */
    public func restoreState(_ state: PlayerTransferState, to player: Player) {
        guard let engine = player.engineService else { return }
        state.apply(to: engine)
    }
}
