import Foundation
import UIKit

/**
 * 播放引擎池插件，管理可复用引擎的入队、出队和生命周期
 */
@MainActor
public final class PlayerEnginePoolPlugin: BasePlugin, PlayerEnginePoolService {

    /** 引擎池存储，按标识符分组 */
    private var pool: [String: [PoolEntry]] = [:]
    /** 池的最大容量 */
    private var _maxCapacity: Int = 4
    /** 每个标识符下的最大引擎数量 */
    private var _maxPerIdentifier: Int = 2
    /** 是否启用自动补充 */
    private var _isAutoReplenishEnabled: Bool = false
    /** 自动补充阈值 */
    private var _autoReplenishThreshold: Float = 0.5
    /** 空闲超时时间 */
    private var _idleTimeout: TimeInterval = 0
    /** 池统计信息 */
    private var _statistics = PlayerEnginePoolStatistics()
    /** 空闲计时器映射 */
    private var idleTimers: [ObjectIdentifier: Timer] = [:]
    /** 引擎工厂闭包 */
    private var engineFactory: (() -> PlayerEngineCoreService?)?

    /**
     * 池条目，封装引擎实例和入队时间
     */
    private struct PoolEntry {
        /** 引擎实例 */
        let engine: PlayerEngineCoreService
        /** 入队时间 */
        let enqueueTime: Date
    }

    /** 池的最大容量（至少为 1） */
    public var maxCapacity: Int {
        get { _maxCapacity }
        set { _maxCapacity = max(1, newValue) }
    }

    /** 每个标识符下的最大引擎数量（至少为 1） */
    public var maxPerIdentifier: Int {
        get { _maxPerIdentifier }
        set { _maxPerIdentifier = max(1, newValue) }
    }

    /** 池中引擎总数 */
    public var count: Int {
        pool.values.reduce(0) { $0 + $1.count }
    }

    /** 是否启用自动补充 */
    public var isAutoReplenishEnabled: Bool {
        get { _isAutoReplenishEnabled }
        set { _isAutoReplenishEnabled = newValue }
    }

    /** 自动补充阈值（0-1） */
    public var autoReplenishThreshold: Float {
        get { _autoReplenishThreshold }
        set { _autoReplenishThreshold = max(0, min(1, newValue)) }
    }

    /** 空闲超时时间 */
    public var idleTimeout: TimeInterval {
        get { _idleTimeout }
        set { _idleTimeout = max(0, newValue) }
    }

    /** 池统计信息 */
    public var statistics: PlayerEnginePoolStatistics {
        _statistics
    }

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 设置引擎工厂，用于创建新引擎实例
     */
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

    /**
     * 将引擎入队到池中
     */
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

    /**
     * 从池中出队一个引擎
     */
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

    /**
     * 获取指定标识符下的引擎数量
     */
    public func count(for identifier: String) -> Int {
        pool[identifier]?.count ?? 0
    }

    /**
     * 预填充池，为指定标识符创建指定数量的引擎
     */
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

    /**
     * 清空整个池
     */
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

    /**
     * 清空指定标识符下的引擎
     */
    public func clear(identifier: String) {
        if let entries = pool.removeValue(forKey: identifier) {
            for entry in entries {
                cancelIdleTimer(for: entry.engine)
                entry.engine.pause()
                entry.engine.replaceCurrentItem(with: nil)
            }
        }
    }

    /**
     * 驱逐指定标识符下最早的引擎
     */
    private func evictOldest(identifier: String) {
        guard var entries = pool[identifier], !entries.isEmpty else { return }
        let removed = entries.removeFirst()
        pool[identifier] = entries.isEmpty ? nil : entries
        cancelIdleTimer(for: removed.engine)
        _statistics.evictions += 1
    }

    /**
     * 驱逐全局最早的引擎
     */
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

    /**
     * 在需要时自动补充引擎
     */
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

    /**
     * 为引擎安排空闲计时器
     */
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

    /**
     * 取消指定引擎的空闲计时器
     */
    private func cancelIdleTimer(for engine: PlayerEngineCoreService) {
        let engineId = ObjectIdentifier(engine as AnyObject)
        idleTimers[engineId]?.invalidate()
        idleTimers.removeValue(forKey: engineId)
    }

    /**
     * 取消所有空闲计时器
     */
    private func cancelAllIdleTimers() {
        idleTimers.values.forEach { $0.invalidate() }
        idleTimers.removeAll()
    }

    /**
     * 移除空闲超时的引擎
     */
    private func removeIdleEngine(_ engine: PlayerEngineCoreService, identifier: String) {
        guard var entries = pool[identifier] else { return }
        let engineObj = engine as AnyObject
        entries.removeAll { ($0.engine as AnyObject) === engineObj }
        pool[identifier] = entries.isEmpty ? nil : entries
        cancelIdleTimer(for: engine)
        _statistics.idleCleanups += 1
    }

    /**
     * 收到内存警告时清空池
     */
    @objc private func didReceiveMemoryWarning() {
        clear()
    }

    /**
     * 应用进入后台时清空池
     */
    @objc private func appDidEnterBackground() {
        clear()
    }
}
