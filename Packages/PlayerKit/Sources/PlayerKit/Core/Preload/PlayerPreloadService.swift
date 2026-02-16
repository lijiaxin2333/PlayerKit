import Foundation

/**
 * 预加载任务类型枚举
 */
public enum PlayerPreloadTaskType: Int {
    /** 视频 */
    case video = 0
    /** 音频 */
    case audio
    /** 封面 */
    case cover
}

/**
 * 预加载任务状态枚举
 */
public enum PlayerPreloadTaskState: Int {
    /** 待处理 */
    case pending = 0
    /** 加载中 */
    case loading
    /** 已完成 */
    case finished
    /** 已取消 */
    case cancelled
    /** 失败 */
    case failed
}

/**
 * 预加载任务协议
 */
@MainActor
public protocol PlayerPreloadTask: AnyObject {
    /** 任务唯一键 */
    var taskKey: String { get }
    /** 任务类型 */
    var taskType: PlayerPreloadTaskType { get }
    /** 目标 URL */
    var url: URL { get }
    /** 预加载大小 */
    var preloadSize: Int64 { get }
    /** 优先级 */
    var priority: Int { get set }
    /** 当前状态 */
    var state: PlayerPreloadTaskState { get }
}

/**
 * 预加载服务协议
 */
@MainActor
public protocol PlayerPreloadService: PluginService {

    /** 最大并发任务数 */
    var maxConcurrentCount: Int { get set }

    /** 是否已暂停 */
    var isPaused: Bool { get }

    /**
     * 添加单个任务
     */
    func addTask(_ task: PlayerPreloadTask)

    /**
     * 添加多个任务
     */
    func addTasks(_ tasks: [PlayerPreloadTask])

    /**
     * 在指定索引插入任务
     */
    func insertTask(_ task: PlayerPreloadTask, at index: Int)

    /**
     * 移除指定键的任务
     */
    func removeTask(forKey key: String)

    /**
     * 移除所有任务
     */
    func removeAllTasks()

    /**
     * 取消指定键的任务
     */
    func cancelTask(forKey key: String)

    /**
     * 取消所有任务
     */
    func cancelAllTasks()

    /**
     * 暂停调度
     */
    func pause()

    /**
     * 恢复调度
     */
    func resume()

    /**
     * 根据键查找任务
     */
    func task(forKey key: String) -> PlayerPreloadTask?

    /** 待处理任务列表 */
    var pendingTasks: [PlayerPreloadTask] { get }

    /** 正在加载的任务列表 */
    var loadingTasks: [PlayerPreloadTask] { get }
}
