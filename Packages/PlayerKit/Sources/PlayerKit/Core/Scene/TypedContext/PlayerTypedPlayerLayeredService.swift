import Foundation

/** 体裁播放器层相关事件定义 */
public extension Event {
    /** 体裁播放器已添加到场景的粘性事件 */
    static let typedPlayerDidAddToSceneSticky: Event = "TypedPlayerDidAddToSceneSticky"
    /** 体裁播放器即将从场景移除的事件 */
    static let typedPlayerWillRemoveFromScene: Event = "TypedPlayerWillRemoveFromScene"
}

/**
 * 播放器体裁播放器层服务协议
 * 提供体裁播放器生命周期管理与分层回调执行能力
 */
@MainActor
public protocol PlayerTypedPlayerLayeredService: PluginService {

    /** 当前是否已添加体裁播放器 */
    var hasPlayer: Bool { get }

    /** 体裁播放器对应的 Context */
    var typedContext: ContextProtocol? { get }

    /** 配置体裁播放器的回调类型 */
    typealias ConfigTypedPlayerBlock = () -> Void
    /** 重置体裁播放器的回调类型 */
    typealias ResetTypedPlayerBlock = () -> Void

    /**
     * 执行配置或重置体裁播放器的回调
     * - Parameters:
     *   - configBlock: 配置体裁播放器时的回调
     *   - resetBlock: 重置体裁播放器时的回调
     */
    func execConfigPlayer(_ configBlock: ConfigTypedPlayerBlock?, execResetPlayer resetBlock: ResetTypedPlayerBlock?)

    /** 分层回调类型，参数 isConfig 表示当前是否为配置状态 */
    typealias TypedPlayerLayeredBlock = (_ isConfig: Bool) -> Void

    /**
     * 执行分层回调
     * - Parameter layeredBlock: 回调闭包
     */
    func execLayeredBlock(_ layeredBlock: TypedPlayerLayeredBlock?)
}
