import Foundation
import UIKit

@MainActor
public final class PlayerTransitionCoordinator {

    public enum Result {
        case success
        case sourceCannotDetach
        case destinationCannotAttach
        case noPlayer
    }

    @discardableResult
    public static func transfer(
        from source: PlayerTransitionSource,
        to destination: PlayerTransitionDestination,
        completion: ((Result) -> Void)? = nil
    ) -> Result {
        guard source.canDetachPlayer() else {
            completion?(.sourceCannotDetach)
            return .sourceCannotDetach
        }

        guard let player = source.transitionPlayer else {
            destination.handleAttachFailed()
            completion?(.noPlayer)
            return .noPlayer
        }

        guard destination.canAttachPlayer(player) else {
            destination.handleAttachFailed()
            completion?(.destinationCannotAttach)
            return .destinationCannotAttach
        }

        source.detachPlayer()
        destination.attachPlayer(player)

        completion?(.success)
        return .success
    }

    @discardableResult
    public static func detach(
        from source: PlayerTransitionSource
    ) -> Player? {
        guard source.canDetachPlayer() else { return nil }
        let player = source.transitionPlayer
        source.detachPlayer()
        return player
    }

    public static func attach(
        _ player: Player,
        to destination: PlayerTransitionDestination
    ) -> Result {
        guard destination.canAttachPlayer(player) else {
            destination.handleAttachFailed()
            return .destinationCannotAttach
        }
        destination.attachPlayer(player)
        return .success
    }
}
