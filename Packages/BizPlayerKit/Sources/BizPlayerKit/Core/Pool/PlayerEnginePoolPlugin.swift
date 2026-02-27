import Foundation

/**
 * 引擎池插件，提供对全局引擎池的服务访问
 * - 作为 PlayerEnginePoolService 的访问入口
 */
@MainActor
public final class PlayerEnginePoolPlugin: BasePlugin, PlayerEnginePoolService {

    /** 全局引擎池 */
    private let pool: PlayerEnginePool = .shared

    /**
     * 初始化
     */
    public required init() {
        super.init()
    }

    // MARK: - PlayerEnginePoolService

    public var maxCapacity: Int {
        get { pool.maxCapacity }
        set { pool.maxCapacity = newValue }
    }

    public var maxPerIdentifier: Int {
        get { pool.maxPerIdentifier }
        set { pool.maxPerIdentifier = newValue }
    }

    public var count: Int { pool.count }

    public var isAutoReplenishEnabled: Bool {
        get { pool.isAutoReplenishEnabled }
        set { pool.isAutoReplenishEnabled = newValue }
    }

    public var autoReplenishThreshold: Float {
        get { pool.autoReplenishThreshold }
        set { pool.autoReplenishThreshold = newValue }
    }

    public var idleTimeout: TimeInterval {
        get { pool.idleTimeout }
        set { pool.idleTimeout = newValue }
    }

    public var statistics: PlayerEnginePoolStatistics { pool.statistics }

    public func enqueue(_ engine: PlayerEngineCoreService, identifier: String) {
        pool.enqueue(engine, identifier: identifier)
    }

    public func dequeue(identifier: String) -> PlayerEngineCoreService? {
        pool.dequeue(identifier: identifier)
    }

    public func count(for identifier: String) -> Int {
        pool.count(for: identifier)
    }

    public func fill(count fillCount: Int, identifier: String) {
        pool.fill(count: fillCount, identifier: identifier)
    }

    public func clear() {
        pool.clear()
    }

    public func clear(identifier: String) {
        pool.clear(identifier: identifier)
    }
}
