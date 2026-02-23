import Foundation
import UIKit
import PlayerKit

@MainActor
public final class FeedPlayerPool {

    public var maxPlayerCount: UInt = 2

    private var idlePlayers: [Player] = []
    private var activePlayers: [String: Player] = [:]

    public init() {}

    public func dequeuePlayer(for videoId: String) -> Player {
        if let player = activePlayers[videoId] {
            return player
        }

        if let player = idlePlayers.first {
            idlePlayers.removeFirst()

            if let playerView = player.playerView, playerView.superview != nil {
                playerView.removeFromSuperview()
            }

            player.willReuse()
            player.releasePlayer()
            player.didReuse()

            activePlayers[videoId] = player
            return player
        }

        let player = Player(name: "FeedPlayerPool.\(UUID().uuidString)")
        activePlayers[videoId] = player
        return player
    }

    @discardableResult
    public func enqueuePlayer(_ player: Player, for videoId: String) -> Bool {
        guard activePlayers[videoId] === player else {
            return false
        }

        guard idlePlayers.count < Int(maxPlayerCount) else {
            activePlayers.removeValue(forKey: videoId)
            player.willRecycle()
            player.destroyPlayer()
            player.didRecycle()
            return false
        }

        activePlayers.removeValue(forKey: videoId)

        player.willRecycle()
        player.releasePlayer()
        player.didRecycle()

        idlePlayers.append(player)
        return true
    }

    public func getActivePlayer(for videoId: String) -> Player? {
        activePlayers[videoId]
    }

    public func pauseAllActivePlayers() {
        activePlayers.values.forEach { $0.pause() }
    }

    public func stopAllActivePlayers() {
        activePlayers.values.forEach { $0.stop() }
    }

    public func releaseAll() {
        activePlayers.values.forEach { player in
            player.willRecycle()
            player.destroyPlayer()
            player.didRecycle()
        }
        idlePlayers.forEach { player in
            player.willRecycle()
            player.destroyPlayer()
            player.didRecycle()
        }
        activePlayers.removeAll()
        idlePlayers.removeAll()
    }

    public func fill() {
        let count = Int(maxPlayerCount) - idlePlayers.count
        guard count > 0 else { return }

        for _ in 0..<count {
            let player = Player(name: "FeedPlayerPool.\(UUID().uuidString)")
            idlePlayers.append(player)
        }
    }

    public var activeCount: Int {
        activePlayers.count
    }

    public var idleCount: Int {
        idlePlayers.count
    }
}

// MARK: - Player Lifecycle Extensions

extension Player {

    func willReuse() {
        engineService?.pause()
    }

    func didReuse() {
    }

    func willRecycle() {
        pause()
    }

    func didRecycle() {
    }

    func releasePlayer() {
        engineService?.pause()
    }

    func destroyPlayer() {
        engineService?.pause()
        engineService?.replaceCurrentItem(with: nil)
    }

    func stop() {
        engineService?.stop()
    }

    func pause() {
        engineService?.pause()
    }

    var playerView: UIView? {
        engineService?.playerView
    }
}
