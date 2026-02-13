import Foundation

public enum PreloadStatus: Sendable, Equatable {
    case idle
    case queued
    case running(progress: Int64)
    case completed
    case failed(String)
}

public protocol PreloadManaging: Sendable {
    func updateWindow(urlsInOrder: [URL], focusIndex: Int) async
    func preload(url: URL, priority: PreloadPriority) async
    func cancel(url: URL) async
    func cancelAll() async
    func status(of url: URL) async -> PreloadStatus
}
