import Foundation

/**
 * 预渲染状态枚举
 */
public enum PreRenderState: Int {
    /** 空闲 */
    case idle = 0
    /** 准备中 */
    case preparing
    /** 已可显示 */
    case readyToDisplay
    /** 可播放 */
    case readyToPlay
    /** 失败 */
    case failed
    /** 已取消 */
    case cancelled
    /** 已超时 */
    case expired
}

/**
 * 预渲染条目
 */
public struct PreRenderEntry {
    /** 目标 URL */
    public let url: URL
    /** 条目标识符 */
    public let identifier: String
    /** 当前状态 */
    public var state: PreRenderState
    /** 关联的播放器 */
    public var player: Player?
    /** 创建时间 */
    public var createTime: Date

    /**
     * 初始化预渲染条目
     */
    public init(url: URL, identifier: String) {
        self.url = url
        self.identifier = identifier
        self.state = .idle
        self.player = nil
        self.createTime = Date()
    }
}

/**
 * 预渲染管理器配置模型
 */
@MainActor
public class PlayerPreRenderManagerConfigModel {
    /** 引擎池服务（弱引用） */
    public weak var enginePool: (any PlayerEnginePoolService)?
    /** 池标识符 */
    public let poolIdentifier: String

    /**
     * 初始化配置
     */
    public init(enginePool: PlayerEnginePoolService, poolIdentifier: String = "default") {
        self.enginePool = enginePool
        self.poolIdentifier = poolIdentifier
    }
}

/**
 * 预渲染管理器服务协议
 */
@MainActor
public protocol PlayerPreRenderManagerService: PluginService {

    /** 最大预渲染数量 */
    var maxPreRenderCount: Int { get set }

    /** 预渲染超时时间 */
    var preRenderTimeout: TimeInterval { get set }

    /** 当前所有活动预渲染条目 */
    var activeEntries: [PreRenderEntry] { get }

    /**
     * 预渲染指定 URL
     */
    func preRender(url: URL, identifier: String)

    /**
     * 批量预渲染多个 URL
     */
    func preRender(urls: [(url: URL, identifier: String)])

    /**
     * 取消指定标识符的预渲染
     */
    func cancelPreRender(identifier: String)

    /**
     * 取消所有预渲染
     */
    func cancelAll()

    /**
     * 消费预渲染好的播放器
     */
    func consumePreRendered(identifier: String) -> Player?

    /**
     * 取出预渲染好的播放器
     */
    func takePlayer(identifier: String) -> Player?

    /**
     * 检查指定标识符是否已预渲染完成
     */
    func isPreRendered(identifier: String) -> Bool

    /**
     * 获取指定标识符的预渲染状态
     */
    func state(for identifier: String) -> PreRenderState
}
