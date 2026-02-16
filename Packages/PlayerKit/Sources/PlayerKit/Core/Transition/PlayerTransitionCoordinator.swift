import Foundation
import UIKit

/**
 * 播放器场景切换协调器
 */
@MainActor
public final class PlayerTransitionCoordinator {

    /**
     * 迁移结果枚举
     */
    public enum Result {
        /** 成功 */
        case success
        /** 源端无法分离 */
        case sourceCannotDetach
        /** 目标端无法附加 */
        case destinationCannotAttach
        /** 无播放器 */
        case noPlayer
    }

    /**
     * 将播放器从源迁移到目标
     * - Returns: 迁移结果
     */
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

    /**
     * 从源端分离播放器
     * - Returns: 分离出的播放器，若无法分离则返回 nil
     */
    @discardableResult
    public static func detach(
        from source: PlayerTransitionSource
    ) -> Player? {
        guard source.canDetachPlayer() else { return nil }
        let player = source.transitionPlayer
        source.detachPlayer()
        return player
    }

    /**
     * 将播放器附加到目标
     * - Returns: 附加结果
     */
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
