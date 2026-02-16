import Foundation

/**
 * 播放引擎池配置模型
 */
public class PlayerEnginePoolConfig {

    /** 池的最大容量 */
    public var maxCapacity: Int

    /** 每个标识符下的最大引擎数量 */
    public var maxPerIdentifier: Int

    /** 是否启用自动补充 */
    public var isAutoReplenishEnabled: Bool

    /** 自动补充的阈值（0-1） */
    public var autoReplenishThreshold: Float

    /** 空闲超时时间 */
    public var idleTimeout: TimeInterval

    /**
     * 初始化播放引擎池配置
     * - Parameters:
     *   - maxCapacity: 池的最大容量，默认 4
     *   - maxPerIdentifier: 每个标识符下的最大数量，默认 2
     *   - isAutoReplenishEnabled: 是否启用自动补充，默认 false
     *   - autoReplenishThreshold: 自动补充阈值，默认 0.5
     *   - idleTimeout: 空闲超时时间，默认 0
     */
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
