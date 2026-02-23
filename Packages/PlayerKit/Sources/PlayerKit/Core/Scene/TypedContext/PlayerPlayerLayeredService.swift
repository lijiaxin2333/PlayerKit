import Foundation

/** 播放器层相关事件定义 */
public extension Event {
    /** 播放器已添加到场景的粘性事件 */
    static let playerDidAddToSceneSticky: Event = "PlayerDidAddToSceneSticky"
    /** 播放器即将从场景移除的事件 */
    static let playerWillRemoveFromScene: Event = "PlayerWillRemoveFromScene"
}

/**
 * 播放器层服务协议
 * 提供播放器生命周期管理与分层回调执行能力
 */
@MainActor
public protocol PlayerPlayerLayeredService: PluginService {

    /** 当前是否已添加播放器 */
    var hasPlayer: Bool { get }

    /** 播放器对应的 Context */
    var playerContext: ContextProtocol? { get }

    /** 配置播放器的回调类型 */
    typealias ConfigPlayerBlock = () -> Void
    /** 重置播放器的回调类型 */
    typealias ResetPlayerBlock = () -> Void

    /**
     * 执行配置或重置播放器的回调
     * - Parameters:
     *   - configBlock: 配置播放器时的回调
     *   - resetBlock: 重置播放器时的回调
     */
    func execConfigPlayer(_ configBlock: ConfigPlayerBlock?, execResetPlayer resetBlock: ResetPlayerBlock?)

    /** 分层回调类型，参数 isConfig 表示当前是否为配置状态 */
    typealias PlayerLayeredBlock = (_ isConfig: Bool) -> Void

    /**
     * 执行分层回调
     * - Parameter layeredBlock: 回调闭包
     */
    func execLayeredBlock(_ layeredBlock: PlayerLayeredBlock?)
}
