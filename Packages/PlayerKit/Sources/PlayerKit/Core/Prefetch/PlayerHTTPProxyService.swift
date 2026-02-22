import Foundation
import KTVHTTPCache

/**
 * HTTP 代理服务协议
 * - 提供 HTTP 代理能力，用于视频缓存
 */
@MainActor
public protocol PlayerHTTPProxyService: PluginService {

    /**
     * 代理是否已启动
     */
    var isProxyStarted: Bool { get }

    /**
     * 启动代理服务（如未启动）
     */
    func startProxyIfNeeded()
}

// MARK: - URL 转换扩展

public extension PlayerHTTPProxyService {
    /**
     * 将原始 URL 转换为代理 URL（非隔离，可从任何线程调用）
     * - 注意：KTVHTTPCache.proxyURL 是线程安全的
     */
    nonisolated func proxyURL(for originalURL: URL) -> URL {
        guard let scheme = originalURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return originalURL
        }
        return KTVHTTPCache.proxyURL(withOriginalURL: originalURL) ?? originalURL
    }
}
