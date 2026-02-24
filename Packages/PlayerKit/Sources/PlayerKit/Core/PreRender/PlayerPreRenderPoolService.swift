import Foundation
import AVFoundation

// MARK: - PreRender Pool Events

public extension Event {
    /// 预渲染任务开始
    static let playerPreRenderPoolDidStart: Event = "PlayerPreRenderPoolDidStart"
    /// 预渲染任务完成
    static let playerPreRenderPoolDidComplete: Event = "PlayerPreRenderPoolDidComplete"
    /// 预渲染任务被消费
    static let playerPreRenderPoolDidConsume: Event = "PlayerPreRenderPoolDidConsume"
    /// 预渲染任务被取消
    static let playerPreRenderPoolDidCancel: Event = "PlayerPreRenderPoolDidCancel"
    /// 预渲染任务超时
    static let playerPreRenderPoolDidTimeout: Event = "PlayerPreRenderPoolDidTimeout"
}

// MARK: - PreRender Entry

/// 预渲染条目信息
public struct PlayerPreRenderEntry: Sendable {
    public let identifier: String
    public let url: URL
    public let state: PlayerPreRenderState
    public let createdAt: Date
    public let completedAt: Date?

    public var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }
}

// MARK: - PreRender Pool Statistics

/// 预渲染池统计信息
public struct PlayerPreRenderPoolStatistics: Sendable {
    public var totalStarted: Int = 0
    public var totalCompleted: Int = 0
    public var totalConsumed: Int = 0
    public var totalCancelled: Int = 0
    public var totalTimeouts: Int = 0
    public var totalEvictions: Int = 0

    public var hitRate: Double {
        let total = totalConsumed + totalCancelled
        guard total > 0 else { return 0 }
        return Double(totalConsumed) / Double(total)
    }
}

// MARK: - PreRender Pool Configuration

/// 预渲染池配置
public struct PlayerPreRenderPoolConfig: Sendable {
    /// 最大预渲染数量
    public let maxCount: Int
    /// 预渲染超时时间（秒）
    public let timeout: TimeInterval
    /// 引擎池标识符
    public let poolIdentifier: String

    public init(
        maxCount: Int = 4,
        timeout: TimeInterval = 10,
        poolIdentifier: String = "default"
    ) {
        self.maxCount = max(1, maxCount)
        self.timeout = max(1, timeout)
        self.poolIdentifier = poolIdentifier
    }
}

// MARK: - PlayerPreRenderPoolService Protocol

@MainActor
public protocol PlayerPreRenderPoolService: AnyObject {

    // MARK: - Configuration

    /// 预渲染池配置
    var config: PlayerPreRenderPoolConfig { get set }

    /// 当前预渲染数量
    var count: Int { get }

    /// 统计信息
    var statistics: PlayerPreRenderPoolStatistics { get }

    // MARK: - Operations

    /// 启动预渲染
    /// - Parameters:
    ///   - url: 视频 URL
    ///   - identifier: 唯一标识符
    ///   - extraConfig: 额外配置（可选）
    func preRender(url: URL, identifier: String, extraConfig: PlayerEngineCoreConfigModel?)

    /// 取消预渲染
    func cancel(identifier: String)

    /// 取消所有预渲染
    func cancelAll()

    /// 消费预渲染结果
    /// - Parameter identifier: 唯一标识符
    /// - Returns: 已预渲染好的引擎，如果不存在或未就绪则返回 nil
    func consume(identifier: String) -> PlayerEngineCoreService?

    /// 消费预渲染结果并转移到目标 Player
    /// - Parameters:
    ///   - identifier: 唯一标识符
    ///   - player: 目标播放器
    /// - Returns: 是否成功转移
    func consumeAndTransfer(identifier: String, to player: Player) -> Bool

    // MARK: - Query

    /// 获取预渲染状态
    func state(for identifier: String) -> PlayerPreRenderState

    /// 获取预渲染条目信息
    func entry(for identifier: String) -> PlayerPreRenderEntry?

    /// 获取所有预渲染条目
    func allEntries() -> [PlayerPreRenderEntry]

    /// 检查是否包含指定标识符
    func contains(identifier: String) -> Bool

    // MARK: - Range Management

    /// 保留指定范围内的预渲染，取消范围外的
    func keepRange(_ range: ClosedRange<Int>, identifierPrefix: String)

    /// 为相邻位置启动预渲染
    /// - Parameters:
    ///   - currentIndex: 当前索引
    ///   - urls: URL 数组
    ///   - identifierPrefix: 标识符前缀
    ///   - offsets: 偏移量数组（默认 [-1, 1, -2, 2]）
    func preRenderAdjacent(
        currentIndex: Int,
        urls: [URL],
        identifierPrefix: String,
        offsets: [Int]
    )
}

// MARK: - Default Implementation

extension PlayerPreRenderPoolService {
    public func preRender(url: URL, identifier: String, extraConfig: PlayerEngineCoreConfigModel? = nil) {
        preRender(url: url, identifier: identifier, extraConfig: extraConfig)
    }

    public func preRenderAdjacent(
        currentIndex: Int,
        urls: [URL],
        identifierPrefix: String,
        offsets: [Int] = [-1, 1, -2, 2]
    ) {
        for offset in offsets {
            let idx = currentIndex + offset
            guard idx >= 0, idx < urls.count else { continue }
            let identifier = "\(identifierPrefix)_\(idx)"
            if state(for: identifier) == .idle {
                preRender(url: urls[idx], identifier: identifier, extraConfig: nil)
            }
        }
    }
}
