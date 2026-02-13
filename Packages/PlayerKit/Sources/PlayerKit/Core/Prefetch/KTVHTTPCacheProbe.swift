import Foundation
import KTVHTTPCache

public enum KTVHTTPCacheProbe {
    private static var started = false

    public static func probeStartProxyIfNeeded() {
        guard !started else { return }
        started = (try? KTVHTTPCache.proxyStart()) != nil
    }

    public static func proxyURL(for originalURL: URL) -> URL {
        probeStartProxyIfNeeded()
        return KTVHTTPCache.proxyURL(withOriginalURL: originalURL) ?? originalURL
    }
}
