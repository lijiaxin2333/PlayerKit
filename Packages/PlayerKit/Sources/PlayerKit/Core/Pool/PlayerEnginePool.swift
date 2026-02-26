import Foundation
import UIKit
import AVFoundation

/// 播放器引擎池
/// 只缓存 AVPlayer + RenderView 这一对核心资源
/// Plugin 每次使用时创建，复用结束后销毁
@MainActor
public final class PlayerEnginePool: PlayerEnginePoolService {

    public static let shared = PlayerEnginePool()

    private var pool: [String: [PoolEntry]] = [:]
    private var _maxCapacity: Int = 4
    private var _maxPerIdentifier: Int = 2
    private var _isAutoReplenishEnabled: Bool = false
    private var _autoReplenishThreshold: Float = 0.5
    private var _idleTimeout: TimeInterval = 0
    private var _statistics = PlayerEnginePoolStatistics()
    private var idleTimers: [String: Timer] = [:]

    /// 池条目：只存储 AVPlayer + RenderView
    private struct PoolEntry {
        let avPlayer: AVPlayer
        let renderView: PlayerEngineRenderView
        let enqueueTime: Date
    }

    public var maxCapacity: Int {
        get { _maxCapacity }
        set { _maxCapacity = max(1, newValue) }
    }

    public var maxPerIdentifier: Int {
        get { _maxPerIdentifier }
        set { _maxPerIdentifier = max(1, newValue) }
    }

    public var count: Int {
        pool.values.reduce(0) { $0 + $1.count }
    }

    public var isAutoReplenishEnabled: Bool {
        get { _isAutoReplenishEnabled }
        set { _isAutoReplenishEnabled = newValue }
    }

    public var autoReplenishThreshold: Float {
        get { _autoReplenishThreshold }
        set { _autoReplenishThreshold = max(0, min(1, newValue)) }
    }

    public var idleTimeout: TimeInterval {
        get { _idleTimeout }
        set { _idleTimeout = max(0, newValue) }
    }

    public var statistics: PlayerEnginePoolStatistics {
        _statistics
    }

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    /// 将引擎的核心资源入队到池中
    /// 会从 Plugin 中提取 AVPlayer + RenderView，Plugin 随后可被销毁
    public func enqueue(_ engine: PlayerEngineCoreService, identifier: String) {
        guard engine.canReuse else { return }
        guard let plugin = engine as? PlayerEngineCorePlugin else { return }

        let identifierCount = pool[identifier]?.count ?? 0
        if identifierCount >= _maxPerIdentifier {
            evictOldest(identifier: identifier)
        }
        if count >= _maxCapacity {
            evictOldestGlobal()
        }

        // 从 Plugin 中提取核心资源
        guard let core = plugin.detachCore() else { return }

        // 准备核心资源用于复用
        core.avPlayer.pause()
        core.renderView.isHidden = true

        if pool[identifier] == nil {
            pool[identifier] = []
        }
        pool[identifier]?.append(PoolEntry(
            avPlayer: core.avPlayer,
            renderView: core.renderView,
            enqueueTime: Date()
        ))
        _statistics.totalEnqueued += 1

        if _idleTimeout > 0 {
            scheduleIdleTimer(forEntryAt: pool[identifier]!.count - 1, identifier: identifier)
        }
    }

    /// 从池中出队核心资源，创建新的 Plugin 接管
    public func dequeue(identifier: String) -> PlayerEngineCoreService? {
        guard var entries = pool[identifier], !entries.isEmpty else {
            _statistics.poolMisses += 1
            _statistics.totalDequeued += 1
            return nil
        }

        let entry = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        _statistics.poolHits += 1
        _statistics.totalDequeued += 1

        cancelIdleTimer(forIdentifier: identifier)

        // 创建新的 Plugin 并接管核心资源
        let newPlugin = PlayerEngineCorePlugin()
        newPlugin.adoptCore(player: entry.avPlayer, renderView: entry.renderView)

        return newPlugin
    }

    public func count(for identifier: String) -> Int {
        pool[identifier]?.count ?? 0
    }

    public func fill(count fillCount: Int, identifier: String) {
        let currentCount = pool[identifier]?.count ?? 0
        let toCreate = min(fillCount, _maxPerIdentifier - currentCount, _maxCapacity - count)
        guard toCreate > 0 else { return }

        for _ in 0..<toCreate {
            let player = AVPlayer()
            player.automaticallyWaitsToMinimizeStalling = false
            player.actionAtItemEnd = .pause

            let renderView = PlayerEngineRenderView(frame: .zero)
            renderView.setPlayer(player)
            renderView.isHidden = true

            if pool[identifier] == nil {
                pool[identifier] = []
            }
            pool[identifier]?.append(PoolEntry(
                avPlayer: player,
                renderView: renderView,
                enqueueTime: Date()
            ))
            _statistics.totalEnqueued += 1

            if _idleTimeout > 0 {
                scheduleIdleTimer(forEntryAt: pool[identifier]!.count - 1, identifier: identifier)
            }
        }
    }

    public func clear() {
        cancelAllIdleTimers()
        for (_, entries) in pool {
            for entry in entries {
                entry.avPlayer.pause()
                entry.avPlayer.replaceCurrentItem(with: nil)
                entry.renderView.removeFromSuperview()
            }
        }
        pool.removeAll()
    }

    public func clear(identifier: String) {
        if let entries = pool.removeValue(forKey: identifier) {
            cancelIdleTimer(forIdentifier: identifier)
            for entry in entries {
                entry.avPlayer.pause()
                entry.avPlayer.replaceCurrentItem(with: nil)
                entry.renderView.removeFromSuperview()
            }
        }
    }

    private func evictOldest(identifier: String) {
        guard var entries = pool[identifier], !entries.isEmpty else { return }
        let removed = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        releaseCore(removed)
        _statistics.evictions += 1
    }

    private func evictOldestGlobal() {
        var oldestId: String?
        var oldestTime = Date.distantFuture

        for (id, entries) in pool {
            if let first = entries.first, first.enqueueTime < oldestTime {
                oldestTime = first.enqueueTime
                oldestId = id
            }
        }

        if let id = oldestId {
            evictOldest(identifier: id)
        }
    }

    private func releaseCore(_ entry: PoolEntry) {
        entry.avPlayer.pause()
        entry.avPlayer.replaceCurrentItem(with: nil)
        entry.renderView.removeFromSuperview()
    }

    private func scheduleIdleTimer(forEntryAt index: Int, identifier: String) {
        let timerKey = "\(identifier)_\(index)"
        idleTimers[timerKey]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: _idleTimeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleIdleTimeout(identifier: identifier)
            }
        }
        idleTimers[timerKey] = timer
    }

    private func cancelIdleTimer(forIdentifier identifier: String) {
        let keysToRemove = idleTimers.keys.filter { $0.hasPrefix(identifier + "_") }
        for key in keysToRemove {
            idleTimers[key]?.invalidate()
            idleTimers.removeValue(forKey: key)
        }
    }

    private func cancelAllIdleTimers() {
        idleTimers.values.forEach { $0.invalidate() }
        idleTimers.removeAll()
    }

    private func handleIdleTimeout(identifier: String) {
        guard var entries = pool[identifier], !entries.isEmpty else { return }
        let removed = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        releaseCore(removed)
        _statistics.idleCleanups += 1
    }

    @objc private func didReceiveMemoryWarning() {
        clear()
    }

    @objc private func appDidEnterBackground() {
        clear()
    }
}
