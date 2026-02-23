import Foundation

/**
 * 播放器扩展层插件
 * 管理 Context 的扩展（Extend）与取消扩展（Unextend）生命周期
 */
@MainActor
public final class PlayerExtensionLayeredPlugin: BasePlugin, PlayerExtensionLayeredService {

    /** 当前是否已扩展到 base context */
    private var _hasExtended: Bool = false
    /** 是否正在进行取消扩展操作 */
    private var isUnextending: Bool = false
    /** 被扩展的基础 Context 的弱引用 */
    private weak var _baseContext: PublicContext?

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成时调用
     * 绑定粘性事件以支持后注册监听者也能收到扩展状态
     * - Parameter context: Context 协议实例
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        // 绑定 sticky event（对齐 Gaga 模式）
        (self.context as? Context)?.bindStickyEvent(.extensionDidAddToContextSticky) { [weak self] in
            guard let self = self, self._hasExtended else { return nil }
            return .shouldSend(self._hasExtended)
        }
    }

    /**
     * Context 完成扩展时调用
     * - Parameter baseContext: 被扩展的基础 Context
     */
    public override func contextDidExtend(on baseContext: PublicContext) {
        super.contextDidExtend(on: baseContext)
        isUnextending = false
        _hasExtended = true
        _baseContext = baseContext
        context?.post(.extensionDidAddToContextSticky, sender: self)
    }

    /**
     * Context 即将取消扩展时调用
     * - Parameter baseContext: 即将取消扩展的基础 Context
     */
    public override func contextWillUnextend(on baseContext: PublicContext) {
        super.contextWillUnextend(on: baseContext)
        isUnextending = true
        context?.post(.extensionWillRemoveFromContext, sender: self)
        isUnextending = false
        _hasExtended = false
        _baseContext = nil
    }

    // MARK: - PlayerExtensionLayeredService

    /** 当前是否已扩展到 base context */
    public var hasExtended: Bool {
        _hasExtended
    }

    /** 被扩展的基础 Context */
    public var baseContext: PublicContext? {
        _baseContext
    }

    /**
     * 执行扩展或取消扩展的回调
     * 根据当前扩展状态执行对应 block
     * - Parameters:
     *   - extendBlock: 扩展状态时的回调
     *   - unExtendBlock: 取消扩展状态时的回调
     */
    public func execExtend(_ extendBlock: (() -> Void)?, execUnExtend unExtendBlock: (() -> Void)?) {
        execLayeredBlock { isExtend in
            if isExtend {
                extendBlock?()
            } else {
                unExtendBlock?()
            }
        }
    }

    /**
     * 执行分层回调
     * 仅在已扩展状态下执行，传入当前是扩展（true）还是取消扩展（false）
     * - Parameter layeredBlock: 回调闭包，参数 isExtend 表示当前是否为扩展状态
     */
    public func execLayeredBlock(_ layeredBlock: ((_ isExtend: Bool) -> Void)?) {
        guard _hasExtended, _baseContext != nil else {
            return
        }
        if isUnextending {
            layeredBlock?(false)
        } else {
            layeredBlock?(true)
        }
    }
}
