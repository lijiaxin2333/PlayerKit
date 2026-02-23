import Foundation
import AVFoundation
import UIKit

// MARK: - Types

public enum PlayerPreRenderState: Int {
    case idle = 0
    case preparing
    case readyToDisplay
    case readyToPlay
    case failed
    case cancelled
    case expired
}

// MARK: - PreRender Events

public extension Event {
    /// 预渲染开始
    static let playerPreRenderStarted: Event = "PlayerPreRenderStarted"
    /// 预渲染就绪
    static let playerPreRenderReady: Event = "PlayerPreRenderReady"
    /// 预渲染超时
    static let playerPreRenderTimeout: Event = "PlayerPreRenderTimeout"
    /// 预加载任务完成
    static let playerPreloadTaskDidFinish: Event = "PlayerPreloadTaskDidFinish"
}

// MARK: - PlayerPreRenderService Protocol

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
