import Foundation

public struct PreloadConfig: Sendable {
    public let maxConcurrent: Int
    public let bytesPerURL: Int64
    public let windowAhead: Int
    public let windowBehind: Int
    public let maxTrackedURLs: Int

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
