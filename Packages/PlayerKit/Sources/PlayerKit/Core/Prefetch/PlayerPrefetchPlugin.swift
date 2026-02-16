import Foundation
import UIKit

@MainActor
public final class PlayerPrefetchPlugin: BasePlugin, PlayerPrefetchService {

    private var _config = PreloadConfig()
    private var manager: KTVHTTPCachePreloadManager?

    public var prefetchConfig: PreloadConfig {
        get { _config }
        set {
            _config = newValue
            manager = KTVHTTPCachePreloadManager(config: newValue)
        }
    }

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        KTVHTTPCacheProbe.probeStartProxyIfNeeded()
        manager = KTVHTTPCachePreloadManager(config: _config)
    }

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        Task { [manager] in
            await manager?.cancelAll()
        }
    }

    public func updateWindow(urls: [URL], focusIndex: Int) {
        guard let manager = manager else { return }
        let captured = urls
        let focus = focusIndex
        Task {
            await manager.updateWindow(urlsInOrder: captured, focusIndex: focus)
        }
    }

    public func prioritize(url: URL) {
        guard let manager = manager else { return }
        let captured = url
        Task {
            await manager.prioritize(url: captured)
        }
    }

    public func cancelAll() {
        Task { [manager] in
            await manager?.cancelAll()
        }
    }

    public func proxyURL(for originalURL: URL) -> URL {
        guard let scheme = originalURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return originalURL
        }
        return KTVHTTPCacheProbe.proxyURL(for: originalURL)
    }
}
