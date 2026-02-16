import Foundation

/** 扩展层相关事件定义 */
public extension Event {
    /** 扩展已添加到 Context 的粘性事件 */
    static let extensionDidAddToContextSticky: Event = "ExtensionDidAddToContextSticky"
    /** 扩展即将从 Context 移除的事件 */
    static let extensionWillRemoveFromContext: Event = "ExtensionWillRemoveFromContext"
}

/**
 * 播放器扩展层服务协议
 * 提供 Context 扩展生命周期管理与分层回调执行能力
 */
@MainActor
public protocol PlayerExtensionLayeredService: PluginService {

    /** 当前是否已扩展到 base context */
    var hasExtended: Bool { get }

    /** 被扩展的基础 Context */
    var baseContext: PublicContext? { get }

    /**
     * 执行扩展或取消扩展的回调
     * - Parameters:
     *   - extendBlock: 扩展状态时的回调
     *   - unExtendBlock: 取消扩展状态时的回调
     */
    func execExtend(_ extendBlock: (() -> Void)?, execUnExtend unExtendBlock: (() -> Void)?)

    /**
     * 执行分层回调
     * - Parameter layeredBlock: 回调闭包，参数 isExtend 表示当前是否为扩展状态
     */
    func execLayeredBlock(_ layeredBlock: ((_ isExtend: Bool) -> Void)?)
}
