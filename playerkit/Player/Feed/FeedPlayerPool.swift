import Foundation
import UIKit

@MainActor
public final class FeedPlayerPool {

    public var maxPlayerCount: UInt = 2

    private var idlePlayers: [FeedPlayer] = []
    private var activePlayers: [String: FeedPlayer] = [:]

    public let configuration: FeedPlayerConfiguration

    public init(configuration: FeedPlayerConfiguration? = nil) {
        self.configuration = configuration ?? FeedPlayerConfiguration()
    }

    public func dequeuePlayer(for videoId: String) -> FeedPlayer {
        if let player = activePlayers[videoId] {
            return player
        }

        if let player = idlePlayers.first {
            idlePlayers.removeFirst()

            if let playerView = player.playerView, playerView.superview != nil {
                playerView.removeFromSuperview()
            }

            player.willReusePlayer()
            player.releasePlayer()
            player.didReusePlayer()

            activePlayers[videoId] = player
            return player
        }

        let player = FeedPlayer(configuration: configuration)
        activePlayers[videoId] = player
        return player
    }

    @discardableResult
    public func enqueuePlayer(_ player: FeedPlayer, for videoId: String) -> Bool {
        guard activePlayers[videoId] === player else {
            return false
        }

        guard idlePlayers.count < Int(maxPlayerCount) else {
            activePlayers.removeValue(forKey: videoId)
            player.willRecyclePlayer()
            player.destroyPlayer()
            player.didRecyclePlayer()
            return false
        }

        activePlayers.removeValue(forKey: videoId)

        player.willRecyclePlayer()
        player.releasePlayer()
        player.didRecyclePlayer()

        idlePlayers.append(player)
        return true
    }

    public func getActivePlayer(for videoId: String) -> FeedPlayer? {
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
            player.willRecyclePlayer()
            player.destroyPlayer()
            player.didRecyclePlayer()
        }
        idlePlayers.forEach { player in
            player.willRecyclePlayer()
            player.destroyPlayer()
            player.didRecyclePlayer()
        }
        activePlayers.removeAll()
        idlePlayers.removeAll()
    }

    public func fill() {
        let count = Int(maxPlayerCount) - idlePlayers.count
        guard count > 0 else { return }

        for _ in 0..<count {
            let player = FeedPlayer(configuration: configuration)
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
