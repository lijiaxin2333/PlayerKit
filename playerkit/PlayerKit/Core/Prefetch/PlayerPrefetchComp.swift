import Foundation
import UIKit

@MainActor
public final class PlayerPrefetchComp: CCLBaseComp, PlayerPrefetchService {

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

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
        KTVHTTPCacheProbe.probeStartProxyIfNeeded()
        manager = KTVHTTPCachePreloadManager(config: _config)
    }

    public override func componentWillUnload(_ context: CCLContextProtocol) {
        super.componentWillUnload(context)
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
