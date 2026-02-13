import Foundation
import UIKit

@MainActor
public protocol PlayerTransitionable: AnyObject {

    var transitionPlayer: Player? { get }

    var playerContainerView: UIView? { get }

    func attachPlayer(_ player: Player)

    func detachPlayer()

    func handleAttachFailed()
}

public extension PlayerTransitionable {

    func performAttachPlayerView(_ player: Player) {
        guard let container = playerContainerView,
              let pv = player.engineService?.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        container.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: container.topAnchor),
            pv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    func performDetachPlayerView() {
        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
    }

    func attachPlayer(_ player: Player) {
        performAttachPlayerView(player)
    }

    func detachPlayer() {
        performDetachPlayerView()
    }

    func handleAttachFailed() {}
}

@MainActor
public protocol PlayerTransitionSource: PlayerTransitionable {

    func canDetachPlayer() -> Bool
}

public extension PlayerTransitionSource {

    func canDetachPlayer() -> Bool { true }
}

@MainActor
public protocol PlayerTransitionDestination: PlayerTransitionable {

    func canAttachPlayer(_ player: Player) -> Bool
}

public extension PlayerTransitionDestination {

    func canAttachPlayer(_ player: Player) -> Bool { true }
}
