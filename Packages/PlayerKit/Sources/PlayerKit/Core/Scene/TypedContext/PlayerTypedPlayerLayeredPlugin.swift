import Foundation

/**
 * 播放器体裁播放器层插件
 * 管理体裁播放器（TypedPlayer）的添加与移除生命周期
 */
@MainActor
public final class PlayerTypedPlayerLayeredPlugin: BasePlugin, PlayerTypedPlayerLayeredService {

    /** 当前是否已添加体裁播放器 */
    private var _hasPlayer: Bool = false
    /** 是否正在进行移除体裁播放器操作 */
    private var isRemovingTypedPlayer: Bool = false
    /** 体裁播放器对应 Context 的弱引用 */
    private weak var _typedContext: ContextProtocol?

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成时调用
     * 绑定粘性事件以支持后注册监听者也能收到体裁播放器添加状态
     * - Parameter context: Context 协议实例
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        (self.context as? Context)?.bindStickyEvent(.typedPlayerDidAddToSceneSticky, value: _hasPlayer)
    }

    /**
     * 子 Context 添加完成时调用
     * 若子 Context 的 holder 为体裁播放器，则更新 hasPlayer 状态
     * - Parameter subContext: 被添加的子 Context
     */
    public override func contextDidAddSubContext(_ subContext: PublicContext) {
        super.contextDidAddSubContext(subContext)

        if let holder = subContext.holder, holder is any TypedPlayerProtocol {
            _hasPlayer = true
            _typedContext = subContext
            context?.post(.typedPlayerDidAddToSceneSticky, sender: self)
        }
    }

    /**
     * 子 Context 即将移除时调用
     * 若子 Context 的 holder 为体裁播放器，则更新 hasPlayer 状态并发送事件
     * - Parameter subContext: 即将移除的子 Context
     */
    public override func contextWillRemoveSubContext(_ subContext: PublicContext) {
        super.contextWillRemoveSubContext(subContext)

        if let holder = subContext.holder, holder is any TypedPlayerProtocol {
            isRemovingTypedPlayer = true
            context?.post(.typedPlayerWillRemoveFromScene, sender: self)
            _hasPlayer = false
            _typedContext = nil
            isRemovingTypedPlayer = false
        }
    }

    // MARK: - PlayerTypedPlayerLayeredService

    /** 当前是否已添加体裁播放器 */
    public var hasPlayer: Bool {
        _hasPlayer
    }

    /** 体裁播放器对应的 Context */
    public var typedContext: ContextProtocol? {
        _typedContext
    }

    /**
     * 执行配置或重置体裁播放器的回调
     * 根据当前体裁播放器状态执行对应 block
     * - Parameters:
     *   - configBlock: 配置体裁播放器时的回调
     *   - resetBlock: 重置体裁播放器时的回调
     */
    public func execConfigPlayer(_ configBlock: ConfigTypedPlayerBlock?, execResetPlayer resetBlock: ResetTypedPlayerBlock?) {
        execLayeredBlock { isConfig in
            if isConfig {
                configBlock?()
            } else {
                resetBlock?()
            }
        }
    }

    /**
     * 执行分层回调
     * 仅在已有体裁播放器时执行，传入当前是配置（true）还是重置（false）
     * - Parameter layeredBlock: 回调闭包，参数 isConfig 表示当前是否为配置状态
     */
    public func execLayeredBlock(_ layeredBlock: TypedPlayerLayeredBlock?) {
        guard _hasPlayer, _typedContext != nil else {
            return
        }

        if isRemovingTypedPlayer {
            layeredBlock?(false)
        } else {
            layeredBlock?(true)
        }
    }
}
