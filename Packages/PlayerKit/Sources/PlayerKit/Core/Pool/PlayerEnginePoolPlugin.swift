import Foundation
import UIKit

@MainActor
public final class PlayerEnginePoolPlugin: BasePlugin, PlayerEnginePoolService {

    private var pool: [String: [PoolEntry]] = [:]
    private var _maxCapacity: Int = 4
    private var _maxPerIdentifier: Int = 2
    private var _isAutoReplenishEnabled: Bool = false
    private var _autoReplenishThreshold: Float = 0.5
    private var _idleTimeout: TimeInterval = 0
    private var _statistics = PlayerEnginePoolStatistics()
    private var idleTimers: [ObjectIdentifier: Timer] = [:]
    private var engineFactory: (() -> PlayerEngineCoreService?)?

    private struct PoolEntry {
        let engine: PlayerEngineCoreService
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

    public required override init() {
        super.init()
    }

    public func setEngineFactory(_ factory: @escaping () -> PlayerEngineCoreService?) {
        engineFactory = factory
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
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

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        NotificationCenter.default.removeObserver(self)
        cancelAllIdleTimers()
        clear()
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let config = configModel as? PlayerEnginePoolConfig else { return }
        _maxCapacity = config.maxCapacity
        _maxPerIdentifier = config.maxPerIdentifier
        _isAutoReplenishEnabled = config.isAutoReplenishEnabled
        _autoReplenishThreshold = config.autoReplenishThreshold
        _idleTimeout = config.idleTimeout
    }

    // MARK: - PlayerEnginePoolService

    public func enqueue(_ engine: PlayerEngineCoreService, identifier: String) {
        guard engine.canReuse else { return }

        let identifierCount = pool[identifier]?.count ?? 0
        if identifierCount >= _maxPerIdentifier {
            evictOldest(identifier: identifier)
        }
        if count >= _maxCapacity {
            evictOldestGlobal()
        }

        engine.prepareForReuse()

        if pool[identifier] == nil {
            pool[identifier] = []
        }
        pool[identifier]?.append(PoolEntry(engine: engine, enqueueTime: Date()))
        _statistics.totalEnqueued += 1
        PLog.poolEnqueue(identifier, countAfter: count)

        if _idleTimeout > 0 {
            scheduleIdleTimer(for: engine, identifier: identifier)
        }

        context?.post(.playerEngineDidEnqueueToPool, object: engine as AnyObject, sender: self)
    }

    public func dequeue(identifier: String) -> PlayerEngineCoreService? {
        guard var entries = pool[identifier], !entries.isEmpty else {
            _statistics.poolMisses += 1
            _statistics.totalDequeued += 1
            PLog.poolDequeue(identifier, hit: false, countAfter: count)
            autoReplenishIfNeeded(identifier: identifier)
            return nil
        }

        let entry = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        _statistics.poolHits += 1
        _statistics.totalDequeued += 1
        PLog.poolDequeue(identifier, hit: true, countAfter: count)

        cancelIdleTimer(for: entry.engine)
        entry.engine.didDequeueForReuse()

        context?.post(.playerEngineDidDequeueFromPool, object: entry.engine as AnyObject, sender: self)

        autoReplenishIfNeeded(identifier: identifier)

        return entry.engine
    }

    public func count(for identifier: String) -> Int {
        pool[identifier]?.count ?? 0
    }

    public func fill(count fillCount: Int, identifier: String) {
        guard let factory = engineFactory else { return }
        let currentCount = pool[identifier]?.count ?? 0
        let toCreate = min(fillCount, _maxPerIdentifier - currentCount, _maxCapacity - count)
        guard toCreate > 0 else { return }

        for _ in 0..<toCreate {
            guard let engine = factory() else { continue }
            engine.prepareForReuse()

            if pool[identifier] == nil {
                pool[identifier] = []
            }
            pool[identifier]?.append(PoolEntry(engine: engine, enqueueTime: Date()))
            _statistics.totalEnqueued += 1

            if _idleTimeout > 0 {
                scheduleIdleTimer(for: engine, identifier: identifier)
            }
        }
    }

    public func clear() {
        cancelAllIdleTimers()
        for (_, entries) in pool {
            for entry in entries {
                entry.engine.pause()
                entry.engine.replaceCurrentItem(with: nil)
            }
        }
        pool.removeAll()
        context?.post(.playerEnginePoolDidClear, sender: self)
    }

    public func clear(identifier: String) {
        if let entries = pool.removeValue(forKey: identifier) {
            for entry in entries {
                cancelIdleTimer(for: entry.engine)
                entry.engine.pause()
                entry.engine.replaceCurrentItem(with: nil)
            }
        }
    }

    // MARK: - Eviction

    private func evictOldest(identifier: String) {
        guard var entries = pool[identifier], !entries.isEmpty else { return }
        let removed = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        cancelIdleTimer(for: removed.engine)
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

    // MARK: - Auto Replenish

    private func autoReplenishIfNeeded(identifier: String) {
        guard _isAutoReplenishEnabled, let factory = engineFactory else { return }

        let currentCount = pool[identifier]?.count ?? 0
        let threshold = Int(Float(_maxPerIdentifier) * _autoReplenishThreshold)

        guard currentCount < threshold else { return }

        let toCreate = min(_maxPerIdentifier - currentCount, _maxCapacity - count)
        guard toCreate > 0 else { return }

        for _ in 0..<toCreate {
            guard let engine = factory() else { continue }
            engine.prepareForReuse()

            if pool[identifier] == nil {
                pool[identifier] = []
            }
            pool[identifier]?.append(PoolEntry(engine: engine, enqueueTime: Date()))
            _statistics.totalEnqueued += 1

            if _idleTimeout > 0 {
                scheduleIdleTimer(for: engine, identifier: identifier)
            }
        }
    }

    // MARK: - Idle Timer

    private func scheduleIdleTimer(for engine: PlayerEngineCoreService, identifier: String) {
        let engineId = ObjectIdentifier(engine as AnyObject)
        idleTimers[engineId]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: _idleTimeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.removeIdleEngine(engine, identifier: identifier)
            }
        }
        idleTimers[engineId] = timer
    }

    private func cancelIdleTimer(for engine: PlayerEngineCoreService) {
        let engineId = ObjectIdentifier(engine as AnyObject)
        idleTimers[engineId]?.invalidate()
        idleTimers.removeValue(forKey: engineId)
    }

    private func cancelAllIdleTimers() {
        idleTimers.values.forEach { $0.invalidate() }
        idleTimers.removeAll()
    }

    private func removeIdleEngine(_ engine: PlayerEngineCoreService, identifier: String) {
        guard var entries = pool[identifier] else { return }
        let engineObj = engine as AnyObject
        entries.removeAll { ($0.engine as AnyObject) === engineObj }
        pool[identifier] = entries.isEmpty ? nil : entries
        cancelIdleTimer(for: engine)
        _statistics.idleCleanups += 1
    }

    // MARK: - Notifications

    @objc private func didReceiveMemoryWarning() {
        clear()
    }

    @objc private func appDidEnterBackground() {
        clear()
    }
}
