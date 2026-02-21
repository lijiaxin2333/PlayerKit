import Foundation
import AVFoundation
import UIKit

public enum PlayerPreRenderState: Int {
    case idle = 0
    case preparing
    case readyToDisplay
    case readyToPlay
    case failed
    case cancelled
    case expired
}

@MainActor
public protocol PlayerPreRenderService: PluginService {

    var preRenderState: PlayerPreRenderState { get }

    var isPrerenderPlaying: Bool { get }

    func prerenderIfNeed()

    func dragPlay()

    func releasePlayer()

    func resetPlayer()

    func attachOnSuperView(_ superView: UIView)

    func removeFromSuperView(_ superView: UIView)

    func detachEngine() -> BasePlugin?
}
