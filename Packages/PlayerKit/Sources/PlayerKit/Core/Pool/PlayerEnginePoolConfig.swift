import Foundation

public class PlayerEnginePoolConfig {

    public var maxCapacity: Int

    public var maxPerIdentifier: Int

    public var isAutoReplenishEnabled: Bool

    public var autoReplenishThreshold: Float

    public var idleTimeout: TimeInterval

    public init(
        maxCapacity: Int = 4,
        maxPerIdentifier: Int = 2,
        isAutoReplenishEnabled: Bool = false,
        autoReplenishThreshold: Float = 0.5,
        idleTimeout: TimeInterval = 0
    ) {
        self.maxCapacity = maxCapacity
        self.maxPerIdentifier = maxPerIdentifier
        self.isAutoReplenishEnabled = isAutoReplenishEnabled
        self.autoReplenishThreshold = autoReplenishThreshold
        self.idleTimeout = idleTimeout
    }
}
