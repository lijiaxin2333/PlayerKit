import Foundation

@MainActor
public final class PlayerSceneTransferComp: CCLBaseComp, PlayerSceneTransferService {

    public required override init() {
        super.init()
    }

    // MARK: - PlayerSceneTransferService

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

    public func detachEngine(from player: Player) -> PlayerEngineCoreService? {
        guard let comp = player.context.detachInstance(for: PlayerEngineCoreService.self) else {
            return nil
        }
        return comp as? PlayerEngineCoreService
    }

    public func attachEngine(_ engine: PlayerEngineCoreService, to player: Player) {
        guard let comp = engine as? CCLBaseComp else { return }
        player.context.registerInstance(comp, protocol: PlayerEngineCoreService.self)
    }

    public func captureState(from player: Player) -> PlayerTransferState? {
        guard let engine = player.engineService else { return nil }
        return PlayerTransferState(from: engine)
    }

    public func restoreState(_ state: PlayerTransferState, to player: Player) {
        guard let engine = player.engineService else { return }
        state.apply(to: engine)
    }
}
