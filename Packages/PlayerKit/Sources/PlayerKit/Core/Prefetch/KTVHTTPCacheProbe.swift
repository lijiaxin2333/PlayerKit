import Foundation
import KTVHTTPCache

/**
 * KTVHTTPCache 探测工具，负责启动代理并转换 URL
 */
public enum KTVHTTPCacheProbe {
    /** 代理是否已启动 */
    private nonisolated(unsafe) static var started = false

    /**
     * 如需则启动 KTVHTTPCache 代理
     */
    public static func probeStartProxyIfNeeded() {
        guard !started else { return }
        started = (try? KTVHTTPCache.proxyStart()) != nil
    }

    /**
     * 将原始 URL 转换为经过代理的 URL
     */
    public static func proxyURL(for originalURL: URL) -> URL {
        probeStartProxyIfNeeded()
        return KTVHTTPCache.proxyURL(withOriginalURL: originalURL) ?? originalURL
    }
}
