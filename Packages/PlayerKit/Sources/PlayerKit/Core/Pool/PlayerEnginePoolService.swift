import Foundation

@MainActor
public protocol PlayerEnginePoolService: AnyObject {

    var maxCapacity: Int { get set }

    var maxPerIdentifier: Int { get set }

    var count: Int { get }

    var isAutoReplenishEnabled: Bool { get set }

    var autoReplenishThreshold: Float { get set }

    var idleTimeout: TimeInterval { get set }

    var statistics: PlayerEnginePoolStatistics { get }

    func enqueue(_ engine: PlayerEngineCoreService, identifier: String)

    func dequeue(identifier: String) -> PlayerEngineCoreService?

    func count(for identifier: String) -> Int

    func fill(count: Int, identifier: String)

    func clear()

    func clear(identifier: String)
}

public struct PlayerEnginePoolStatistics {
    public var totalEnqueued: Int = 0
    public var totalDequeued: Int = 0
    public var poolHits: Int = 0
    public var poolMisses: Int = 0
    public var evictions: Int = 0
    public var idleCleanups: Int = 0

    public var hitRate: Double {
        let total = poolHits + poolMisses
        guard total > 0 else { return 0 }
        return Double(poolHits) / Double(total)
    }
}
