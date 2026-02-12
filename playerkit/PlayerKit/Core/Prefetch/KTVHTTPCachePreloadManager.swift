import Foundation
import KTVHTTPCache

private struct QueueEntry: Sendable {
    let url: URL
    var priority: PreloadPriority
    let enqueuedAt: UInt64
}

private final class RunningHandle {
    let url: URL
    var receivedBytes: Int64 = 0
    var task: URLSessionDataTask?
    init(url: URL) { self.url = url }
}

public actor KTVHTTPCachePreloadManager: PreloadManaging {
    private let config: PreloadConfig
    private let session: URLSession

    private var statusMap: [URL: PreloadStatus] = [:]
    private var queued: [URL: QueueEntry] = [:]
    private var running: [URL: RunningHandle] = [:]
    private var completed: Set<URL> = []
    private var trackedOrder: [URL] = []

    private var lastWindowSet: Set<URL> = []

    public init(config: PreloadConfig) {
        self.config = config
        let cfg = URLSessionConfiguration.default
        cfg.requestCachePolicy = .reloadIgnoringLocalCacheData
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: cfg)
    }

    public func status(of url: URL) async -> PreloadStatus {
        return statusMap[url] ?? .idle
    }

    public func updateWindow(urlsInOrder: [URL], focusIndex: Int) async {
        guard !urlsInOrder.isEmpty else { return }
        let lower = max(0, focusIndex - config.windowBehind)
        let upper = min(urlsInOrder.count - 1, focusIndex + config.windowAhead)
        if lower > upper { return }

        let windowSlice = urlsInOrder[lower...upper]
        let windowSet = Set(windowSlice)

        for (u, _) in queued where !windowSet.contains(u) {
            queued.removeValue(forKey: u)
            clearIdleState(for: u)
        }
        for (u, handle) in running where !windowSet.contains(u) {
            handle.task?.cancel()
            running.removeValue(forKey: u)
            clearIdleState(for: u)
        }

        for (idx, u) in windowSlice.enumerated() {
            if completed.contains(u) {
                activateTracking(for: u)
                continue
            }
            if running[u] != nil {
                activateTracking(for: u)
                continue
            }
            let absoluteIndex = lower + idx
            let desiredPriority: PreloadPriority = {
                if absoluteIndex == focusIndex { return .urgent }
                if absoluteIndex < focusIndex { return .low }
                return .normal
            }()

            if var existing = queued[u] {
                if desiredPriority > existing.priority { existing.priority = desiredPriority }
                queued[u] = existing
            } else {
                queued[u] = QueueEntry(url: u, priority: desiredPriority, enqueuedAt: nowTick())
            }
            statusMap[u] = .queued
            activateTracking(for: u)
        }

        lastWindowSet = windowSet
        schedule()
    }

    public func preload(url: URL, priority: PreloadPriority) async {
        if completed.contains(url) {
            activateTracking(for: url)
            return
        }
        if running[url] != nil {
            statusMap[url] = .running(progress: running[url]?.receivedBytes ?? 0)
            activateTracking(for: url)
            return
        }
        if var entry = queued[url] {
            if priority > entry.priority { entry.priority = priority }
            queued[url] = entry
        } else {
            queued[url] = QueueEntry(url: url, priority: priority, enqueuedAt: nowTick())
        }
        statusMap[url] = .queued
        activateTracking(for: url)
        schedule()
    }

    public func prioritize(url: URL) async {
        if completed.contains(url) || running[url] != nil { return }

        if var entry = queued[url] {
            entry.priority = .urgent
            queued[url] = entry
        } else {
            queued[url] = QueueEntry(url: url, priority: .urgent, enqueuedAt: nowTick())
            statusMap[url] = .queued
            activateTracking(for: url)
        }

        if running.count >= config.maxConcurrent {
            let lowest = running.min { a, b in
                let pa = queued[a.key]?.priority ?? .low
                let pb = queued[b.key]?.priority ?? .low
                return pa < pb
            }
            if let victim = lowest {
                victim.value.task?.cancel()
                running.removeValue(forKey: victim.key)
                queued[victim.key] = QueueEntry(url: victim.key, priority: .low, enqueuedAt: nowTick())
                statusMap[victim.key] = .queued
            }
        }

        schedule()
    }

    public func cancel(url: URL) async {
        queued.removeValue(forKey: url)
        if let handle = running.removeValue(forKey: url) {
            handle.task?.cancel()
        }
        clearIdleState(for: url)
    }

    public func cancelAll() async {
        queued.removeAll()
        for (_, handle) in running { handle.task?.cancel() }
        running.removeAll()
        statusMap.removeAll()
        completed.removeAll()
        lastWindowSet.removeAll()
        trackedOrder.removeAll()
    }

    // MARK: - Scheduling

    private func schedule() {
        guard running.count < config.maxConcurrent else { return }
        let need = config.maxConcurrent - running.count
        if need <= 0 { return }

        let candidates = queued.values.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.enqueuedAt < rhs.enqueuedAt
        }
        var started = 0
        for entry in candidates {
            if started >= need { break }
            if running[entry.url] != nil { continue }
            queued.removeValue(forKey: entry.url)
            startPreload(url: entry.url)
            started += 1
        }
    }

    private func startPreload(url: URL) {
        let proxy = KTVHTTPCacheProbe.proxyURL(for: url)

        var req = URLRequest(url: proxy)
        if config.bytesPerURL > 0 {
            let upper = config.bytesPerURL - 1
            req.setValue("bytes=0-\(upper)", forHTTPHeaderField: "Range")
        }
        req.httpMethod = "GET"

        let handle = RunningHandle(url: url)
        running[url] = handle
        statusMap[url] = .running(progress: 0)
        activateTracking(for: url)

        let task = session.dataTask(with: req) { [weak handle] data, response, error in
            Task { [weak handle] in
                await self.finishTask(url: url, data: data, response: response, error: error, handle: handle)
            }
        }
        handle.task = task
        task.resume()
    }

    private func finishTask(url: URL, data: Data?, response: URLResponse?, error: Error?, handle: RunningHandle?) {
        running.removeValue(forKey: url)

        if let err = error as NSError? {
            if err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled {
                clearIdleState(for: url)
                schedule()
                return
            }
            statusMap[url] = .failed(err.localizedDescription)
            activateTracking(for: url)
            schedule()
            return
        }

        if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
            completed.insert(url)
            statusMap[url] = .completed
        } else {
            statusMap[url] = .failed("bad status")
        }
        activateTracking(for: url)
        schedule()
    }

    // MARK: - Utils

    private func activateTracking(for url: URL) {
        touchTracked(url)
        trimTracked(excluding: Set(running.keys))
    }

    private func touchTracked(_ url: URL) {
        if let idx = trackedOrder.firstIndex(of: url) {
            trackedOrder.remove(at: idx)
        }
        trackedOrder.append(url)
    }

    private func removeTracked(_ url: URL) {
        trackedOrder.removeAll { $0 == url }
    }

    private func trimTracked(excluding protected: Set<URL>) {
        guard trackedOrder.count > config.maxTrackedURLs else { return }
        while trackedOrder.count > config.maxTrackedURLs {
            guard let index = trackedOrder.firstIndex(where: { !protected.contains($0) }) else { break }
            let candidate = trackedOrder.remove(at: index)
            purgeState(for: candidate)
        }
    }

    private func purgeState(for url: URL) {
        queued.removeValue(forKey: url)
        completed.remove(url)
        statusMap.removeValue(forKey: url)
    }

    private func clearIdleState(for url: URL) {
        purgeState(for: url)
        removeTracked(url)
    }

    private func nowTick() -> UInt64 {
        var t = timespec()
        clock_gettime(CLOCK_MONOTONIC_RAW, &t)
        return UInt64(t.tv_sec) * 1_000_000_000 + UInt64(t.tv_nsec)
    }
}
