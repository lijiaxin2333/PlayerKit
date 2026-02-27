import Foundation

/**
 * 预加载配置
 */
public struct PreloadConfig: Sendable {
    /** 最大并发预加载数 */
    public let maxConcurrent: Int
    /** 每个 URL 预加载的字节数 */
    public let bytesPerURL: Int64
    /** 焦点前方的窗口大小 */
    public let windowAhead: Int
    /** 焦点后方的窗口大小 */
    public let windowBehind: Int
    /** 最大追踪 URL 数量 */
    public let maxTrackedURLs: Int

    /**
     * 初始化预加载配置
     * - Parameters:
     *   - maxConcurrent: 最大并发数，默认 2
     *   - bytesPerURL: 每 URL 字节数，默认 512KB
     *   - windowAhead: 前方窗口，默认 2
     *   - windowBehind: 后方窗口，默认 2
     *   - maxTrackedURLs: 最大追踪 URL 数，默认 10
     */
    public init(
        maxConcurrent: Int = 2,
        bytesPerURL: Int64 = 1 * 1024 * 512,
        windowAhead: Int = 2,
        windowBehind: Int = 2,
        maxTrackedURLs: Int = 10
    ) {
        let normalizedMaxConcurrent = max(1, maxConcurrent)
        let normalizedBytesPerURL = max(0, bytesPerURL)
        let normalizedWindowAhead = max(0, windowAhead)
        let normalizedWindowBehind = max(0, windowBehind)
        let normalizedTracked = max(1, maxTrackedURLs)
        let minimumTracked = max(normalizedWindowAhead + normalizedWindowBehind + 1, normalizedMaxConcurrent)

        self.maxConcurrent = normalizedMaxConcurrent
        self.bytesPerURL = normalizedBytesPerURL
        self.windowAhead = normalizedWindowAhead
        self.windowBehind = normalizedWindowBehind
        self.maxTrackedURLs = max(normalizedTracked, minimumTracked)
    }
}
