import Foundation
import AVFoundation

/**
 * 预渲染池插件，提供对全局预渲染池的服务访问
 * - 作为 PlayerPreRenderPoolService 的访问入口
 */
@MainActor
public final class PlayerPreRenderPoolPlugin: BasePlugin, PlayerPreRenderPoolService {

    /** 预渲染池实例 */
    private let pool: PlayerPreRenderPool

    /** 是否使用共享实例 */
    private let useShared: Bool

    /**
     * 使用共享实例初始化
     */
    public required init() {
        self.pool = .shared
        self.useShared = true
        super.init()
    }

    /**
     * 使用自定义配置初始化
     */
    public init(config: PlayerPreRenderPoolConfig) {
        self.pool = PlayerPreRenderPool(config: config)
        self.useShared = false
        super.init()
    }

    // MARK: - PlayerPreRenderPoolService

    public var config: PlayerPreRenderPoolConfig {
        get { pool.config }
        set { pool.config = newValue }
    }

    public var count: Int { pool.count }

    public var statistics: PlayerPreRenderPoolStatistics { pool.statistics }

    public func preRender(url: URL, identifier: String, extraConfig: PlayerEngineCoreConfigModel?) {
        pool.preRender(url: url, identifier: identifier, extraConfig: extraConfig)
    }

    public func cancel(identifier: String) {
        pool.cancel(identifier: identifier)
    }

    public func cancelAll() {
        pool.cancelAll()
    }

    public func consume(identifier: String) -> PlayerEngineCoreService? {
        pool.consume(identifier: identifier)
    }

    public func consumeAndTransfer(identifier: String, to player: Player) -> Bool {
        pool.consumeAndTransfer(identifier: identifier, to: player)
    }

    public func state(for identifier: String) -> PlayerPreRenderState {
        pool.state(for: identifier)
    }

    public func entry(for identifier: String) -> PlayerPreRenderEntry? {
        pool.entry(for: identifier)
    }

    public func allEntries() -> [PlayerPreRenderEntry] {
        pool.allEntries()
    }

    public func contains(identifier: String) -> Bool {
        pool.contains(identifier: identifier)
    }

    public func keepRange(_ range: ClosedRange<Int>, identifierPrefix: String) {
        pool.keepRange(range, identifierPrefix: identifierPrefix)
    }

    public func preRenderAdjacent(
        currentIndex: Int,
        urls: [URL],
        identifierPrefix: String,
        offsets: [Int]
    ) {
        pool.preRenderAdjacent(
            currentIndex: currentIndex,
            urls: urls,
            identifierPrefix: identifierPrefix,
            offsets: offsets
        )
    }
}
