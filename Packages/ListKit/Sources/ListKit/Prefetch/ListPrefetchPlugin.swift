import Foundation
import PlayerKit

/**
 * 列表预加载插件，封装 KTVHTTPCache 预加载能力
 * - 独立于 PlayerKit 的插件体系，是 ListKit 层的服务组件
 */
@MainActor
public final class ListPrefetchPlugin: ListPrefetchService {

    /** 预加载配置 */
    private var _config = PreloadConfig()
    /** 预加载管理器实例 */
    private var manager: KTVHTTPCachePreloadManager?

    /** 预加载配置 */
    public var prefetchConfig: PreloadConfig {
        get { _config }
        set {
            _config = newValue
            manager = KTVHTTPCachePreloadManager(config: newValue)
        }
    }

    /**
     * 初始化插件
     */
    public init(config: PreloadConfig = PreloadConfig()) {
        self._config = config
        KTVHTTPCacheProbe.probeStartProxyIfNeeded()
        manager = KTVHTTPCachePreloadManager(config: _config)
    }

    deinit {
        Task { [manager] in
            await manager?.cancelAll()
        }
    }

    /**
     * 更新预加载窗口
     */
    public func updateWindow(urls: [URL], focusIndex: Int) {
        guard let manager = manager else { return }
        let captured = urls
        let focus = focusIndex
        Task {
            await manager.updateWindow(urlsInOrder: captured, focusIndex: focus)
        }
    }

    /**
     * 提升指定 URL 的预加载优先级
     */
    public func prioritize(url: URL) {
        guard let manager = manager else { return }
        let captured = url
        Task {
            await manager.prioritize(url: captured)
        }
    }

    /**
     * 取消所有预加载任务
     */
    public func cancelAll() {
        Task { [manager] in
            await manager?.cancelAll()
        }
    }

    /**
     * 将原始 URL 转换为代理 URL（仅限 http/https）
     */
    public func proxyURL(for originalURL: URL) -> URL {
        guard let scheme = originalURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return originalURL
        }
        return KTVHTTPCacheProbe.proxyURL(for: originalURL)
    }
}
