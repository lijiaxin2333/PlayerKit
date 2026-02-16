import Foundation

/**
 * 预加载服务协议
 */
@MainActor
public protocol PlayerPrefetchService: PluginService {
    /** 预加载配置 */
    var prefetchConfig: PreloadConfig { get set }
    /**
     * 更新预加载窗口
     */
    func updateWindow(urls: [URL], focusIndex: Int)
    /**
     * 提升指定 URL 的预加载优先级
     */
    func prioritize(url: URL)
    /**
     * 取消所有预加载任务
     */
    func cancelAll()
    /**
     * 将原始 URL 转换为代理 URL
     */
    func proxyURL(for originalURL: URL) -> URL
}
