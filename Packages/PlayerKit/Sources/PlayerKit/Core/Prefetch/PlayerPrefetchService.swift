import Foundation

@MainActor
public protocol PlayerPrefetchService: PluginService {
    var prefetchConfig: PreloadConfig { get set }
    func updateWindow(urls: [URL], focusIndex: Int)
    func prioritize(url: URL)
    func cancelAll()
    func proxyURL(for originalURL: URL) -> URL
}
