import Foundation
import KTVHTTPCache

/**
 * HTTP 代理插件，基于 KTVHTTPCache 提供视频缓存代理能力
 * - `proxyURL(for:)` 由协议扩展提供，自动调用 KTVHTTPCache
 */
@MainActor
public final class PlayerHTTPProxyPlugin: BasePlugin, PlayerHTTPProxyService {

    /** 代理是否已启动 */
    private var _isProxyStarted: Bool = false

    /** 代理是否已启动 */
    public var isProxyStarted: Bool { _isProxyStarted }

    /**
     * 初始化
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成，自动启动代理
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        startProxyIfNeeded()
    }

    /**
     * 启动代理服务
     */
    public func startProxyIfNeeded() {
        guard !_isProxyStarted else { return }
        _isProxyStarted = (try? KTVHTTPCache.proxyStart()) != nil
    }
}
