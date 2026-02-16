import Foundation

/**
 * 播放引擎池服务协议，定义引擎池的公共接口
 */
@MainActor
public protocol PlayerEnginePoolService: PluginService {

    /** 池的最大容量 */
    var maxCapacity: Int { get set }

    /** 每个标识符下的最大引擎数量 */
    var maxPerIdentifier: Int { get set }

    /** 池中引擎总数 */
    var count: Int { get }

    /** 是否启用自动补充 */
    var isAutoReplenishEnabled: Bool { get set }

    /** 自动补充阈值（0-1） */
    var autoReplenishThreshold: Float { get set }

    /** 空闲超时时间 */
    var idleTimeout: TimeInterval { get set }

    /** 池统计信息 */
    var statistics: PlayerEnginePoolStatistics { get }

    /**
     * 将引擎入队到池中
     */
    func enqueue(_ engine: PlayerEngineCoreService, identifier: String)

    /**
     * 从池中出队一个引擎
     */
    func dequeue(identifier: String) -> PlayerEngineCoreService?

    /**
     * 获取指定标识符下的引擎数量
     */
    func count(for identifier: String) -> Int

    /**
     * 预填充池
     */
    func fill(count: Int, identifier: String)

    /**
     * 清空整个池
     */
    func clear()

    /**
     * 清空指定标识符下的引擎
     */
    func clear(identifier: String)
}

/**
 * 播放引擎池统计信息
 */
public struct PlayerEnginePoolStatistics {
    /** 总入队次数 */
    public var totalEnqueued: Int = 0
    /** 总出队次数 */
    public var totalDequeued: Int = 0
    /** 池命中次数 */
    public var poolHits: Int = 0
    /** 池未命中次数 */
    public var poolMisses: Int = 0
    /** 驱逐次数 */
    public var evictions: Int = 0
    /** 空闲清理次数 */
    public var idleCleanups: Int = 0

    /** 命中率（0-1） */
    public var hitRate: Double {
        let total = poolHits + poolMisses
        guard total > 0 else { return 0 }
        return Double(poolHits) / Double(total)
    }
}
