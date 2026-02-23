import Foundation

/**
 * 播放器层插件
 * 管理播放器（Player）的添加与移除生命周期
 */
@MainActor
public final class PlayerPlayerLayeredPlugin: BasePlugin, PlayerPlayerLayeredService {

    /** 当前是否已添加播放器 */
    private var _hasPlayer: Bool = false
    /** 是否正在进行移除播放器操作 */
    private var isRemovingPlayer: Bool = false
    /** 播放器对应 Context 的弱引用 */
    private weak var _playerContext: ContextProtocol?

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成时调用
     * 绑定粘性事件以支持后注册监听者也能收到播放器添加状态
     * - Parameter context: Context 协议实例
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        // 绑定 sticky event（对齐 Gaga 模式）
        (self.context as? Context)?.bindStickyEvent(.playerDidAddToSceneSticky) { [weak self] in
            guard let self = self, self._hasPlayer else { return nil }
            return .shouldSend(self._hasPlayer)
        }
    }

    /**
     * 子 Context 添加完成时调用
     * 若子 Context 的 holder 为播放器，则更新 hasPlayer 状态
     * - Parameter subContext: 被添加的子 Context
     */
    public override func contextDidAddSubContext(_ subContext: PublicContext) {
        super.contextDidAddSubContext(subContext)

        if let holder = subContext.holder, holder is Player {
            _hasPlayer = true
            _playerContext = subContext
            context?.post(.playerDidAddToSceneSticky, sender: self)
        }
    }

    /**
     * 子 Context 即将移除时调用
     * 若子 Context 的 holder 为播放器，则更新 hasPlayer 状态并发送事件
     * - Parameter subContext: 即将移除的子 Context
     */
    public override func contextWillRemoveSubContext(_ subContext: PublicContext) {
        super.contextWillRemoveSubContext(subContext)

        if let holder = subContext.holder, holder is Player {
            isRemovingPlayer = true
            context?.post(.playerWillRemoveFromScene, sender: self)
            _hasPlayer = false
            _playerContext = nil
            isRemovingPlayer = false
        }
    }

    // MARK: - PlayerPlayerLayeredService

    /** 当前是否已添加播放器 */
    public var hasPlayer: Bool {
        _hasPlayer
    }

    /** 播放器对应的 Context */
    public var playerContext: ContextProtocol? {
        _playerContext
    }

    /**
     * 执行配置或重置播放器的回调
     * 根据当前播放器状态执行对应 block
     * - Parameters:
     *   - configBlock: 配置播放器时的回调
     *   - resetBlock: 重置播放器时的回调
     */
    public func execConfigPlayer(_ configBlock: ConfigPlayerBlock?, execResetPlayer resetBlock: ResetPlayerBlock?) {
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
     * 仅在已有播放器时执行，传入当前是配置（true）还是重置（false）
     * - Parameter layeredBlock: 回调闭包，参数 isConfig 表示当前是否为配置状态
     */
    public func execLayeredBlock(_ layeredBlock: PlayerLayeredBlock?) {
        guard _hasPlayer, _playerContext != nil else {
            return
        }

        if isRemovingPlayer {
            layeredBlock?(false)
        } else {
            layeredBlock?(true)
        }
    }
}
