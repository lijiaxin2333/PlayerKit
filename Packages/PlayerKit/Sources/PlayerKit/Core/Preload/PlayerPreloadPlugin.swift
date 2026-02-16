import Foundation
import AVFoundation

/**
 * 预加载任务实现类
 */
@MainActor
public final class PlayerPreloadTaskImpl: PlayerPreloadTask {

    /** 任务唯一键 */
    public let taskKey: String
    /** 任务类型 */
    public let taskType: PlayerPreloadTaskType
    /** 目标 URL */
    public let url: URL
    /** 预加载大小 */
    public let preloadSize: Int64
    /** 优先级 */
    public var priority: Int
    /** 当前状态（只读） */
    public private(set) var state: PlayerPreloadTaskState = .pending

    /** AV 资源 */
    private var asset: AVURLAsset?
    /** 需要异步加载的键 */
    private var loadingKeys = ["playable", "duration"]

    /**
     * 初始化预加载任务
     */
    public init(key: String, url: URL, type: PlayerPreloadTaskType = .video, preloadSize: Int64 = 1024 * 1024, priority: Int = 0) {
        self.taskKey = key
        self.url = url
        self.taskType = type
        self.preloadSize = preloadSize
        self.priority = priority
    }

    /**
     * 启动预加载
     */
    func start(completion: @escaping (Bool) -> Void) {
        guard state == .pending else {
            completion(false)
            return
        }
        state = .loading
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        self.asset = asset
        asset.loadValuesAsynchronously(forKeys: loadingKeys) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.state == .loading else { return }
                var allLoaded = true
                for key in self.loadingKeys {
                    var error: NSError?
                    let status = asset.statusOfValue(forKey: key, error: &error)
                    if status != .loaded {
                        allLoaded = false
                        break
                    }
                }
                self.state = allLoaded ? .finished : .failed
                completion(allLoaded)
            }
        }
    }

    /**
     * 取消预加载
     */
    func cancel() {
        guard state == .pending || state == .loading else { return }
        asset?.cancelLoading()
        asset = nil
        state = .cancelled
    }
}

/**
 * 预加载插件，管理预加载任务队列和并发
 */
@MainActor
public final class PlayerPreloadPlugin: BasePlugin, PlayerPreloadService {

    /** 最大并发任务数 */
    public var maxConcurrentCount: Int = 3

    /** 是否已暂停（只读） */
    public private(set) var isPaused: Bool = false

    /** 任务队列 */
    private var taskQueue: [PlayerPreloadTask] = []
    /** 正在执行的任务映射 */
    private var activeTasks: [String: PlayerPreloadTask] = [:]

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    /**
     * 添加单个任务
     */
    public func addTask(_ task: PlayerPreloadTask) {
        guard self.task(forKey: task.taskKey) == nil else { return }
        taskQueue.append(task)
        scheduleNext()
    }

    /**
     * 添加多个任务
     */
    public func addTasks(_ tasks: [PlayerPreloadTask]) {
        for task in tasks {
            guard self.task(forKey: task.taskKey) == nil else { continue }
            taskQueue.append(task)
        }
        scheduleNext()
    }

    /**
     * 在指定索引插入任务
     */
    public func insertTask(_ task: PlayerPreloadTask, at index: Int) {
        guard self.task(forKey: task.taskKey) == nil else { return }
        let idx = min(index, taskQueue.count)
        taskQueue.insert(task, at: idx)
        scheduleNext()
    }

    /**
     * 移除指定键的任务
     */
    public func removeTask(forKey key: String) {
        taskQueue.removeAll { $0.taskKey == key }
        if let active = activeTasks.removeValue(forKey: key) {
            (active as? PlayerPreloadTaskImpl)?.cancel()
        }
    }

    /**
     * 移除所有任务
     */
    public func removeAllTasks() {
        for task in taskQueue {
            (task as? PlayerPreloadTaskImpl)?.cancel()
        }
        taskQueue.removeAll()
        for (_, task) in activeTasks {
            (task as? PlayerPreloadTaskImpl)?.cancel()
        }
        activeTasks.removeAll()
    }

    /**
     * 取消指定键的任务
     */
    public func cancelTask(forKey key: String) {
        if let active = activeTasks.removeValue(forKey: key) {
            (active as? PlayerPreloadTaskImpl)?.cancel()
            scheduleNext()
        }
        if let idx = taskQueue.firstIndex(where: { $0.taskKey == key }) {
            (taskQueue[idx] as? PlayerPreloadTaskImpl)?.cancel()
            taskQueue.remove(at: idx)
        }
    }

    /**
     * 取消所有任务
     */
    public func cancelAllTasks() {
        removeAllTasks()
    }

    /**
     * 暂停调度
     */
    public func pause() {
        isPaused = true
    }

    /**
     * 恢复调度
     */
    public func resume() {
        isPaused = false
        scheduleNext()
    }

    /**
     * 根据键查找任务
     */
    public func task(forKey key: String) -> PlayerPreloadTask? {
        if let active = activeTasks[key] { return active }
        return taskQueue.first { $0.taskKey == key }
    }

    /** 待处理任务列表 */
    public var pendingTasks: [PlayerPreloadTask] {
        taskQueue.filter { $0.state == .pending }
    }

    /** 正在加载的任务列表 */
    public var loadingTasks: [PlayerPreloadTask] {
        Array(activeTasks.values)
    }

    /**
     * 调度下一个待执行任务
     */
    private func scheduleNext() {
        guard !isPaused else { return }
        while activeTasks.count < maxConcurrentCount, let next = nextPendingTask() {
            startTask(next)
        }
    }

    /**
     * 获取下一个待处理任务
     */
    private func nextPendingTask() -> PlayerPreloadTask? {
        guard let idx = taskQueue.firstIndex(where: { $0.state == .pending }) else { return nil }
        return taskQueue.remove(at: idx)
    }

    /**
     * 启动指定任务
     */
    private func startTask(_ task: PlayerPreloadTask) {
        activeTasks[task.taskKey] = task
        guard let impl = task as? PlayerPreloadTaskImpl else {
            activeTasks.removeValue(forKey: task.taskKey)
            return
        }
        impl.start { [weak self] _ in
            guard let self = self else { return }
            self.activeTasks.removeValue(forKey: task.taskKey)
            self.context?.post(.playerPreloadTaskDidFinish, object: task as AnyObject, sender: self)
            self.scheduleNext()
        }
    }
}
