import Foundation
import AVFoundation

@MainActor
public final class PlayerPreloadTaskImpl: PlayerPreloadTask {

    public let taskKey: String
    public let taskType: PlayerPreloadTaskType
    public let url: URL
    public let preloadSize: Int64
    public var priority: Int
    public private(set) var state: PlayerPreloadTaskState = .pending

    private var asset: AVURLAsset?
    private var loadingKeys = ["playable", "duration"]

    public init(key: String, url: URL, type: PlayerPreloadTaskType = .video, preloadSize: Int64 = 1024 * 1024, priority: Int = 0) {
        self.taskKey = key
        self.url = url
        self.taskType = type
        self.preloadSize = preloadSize
        self.priority = priority
    }

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

    func cancel() {
        guard state == .pending || state == .loading else { return }
        asset?.cancelLoading()
        asset = nil
        state = .cancelled
    }
}

@MainActor
public final class PlayerPreloadPlugin: BasePlugin, PlayerPreloadService {

    public var maxConcurrentCount: Int = 3

    public private(set) var isPaused: Bool = false

    private var taskQueue: [PlayerPreloadTask] = []
    private var activeTasks: [String: PlayerPreloadTask] = [:]

    public required override init() {
        super.init()
    }

    public func addTask(_ task: PlayerPreloadTask) {
        guard self.task(forKey: task.taskKey) == nil else { return }
        taskQueue.append(task)
        scheduleNext()
    }

    public func addTasks(_ tasks: [PlayerPreloadTask]) {
        for task in tasks {
            guard self.task(forKey: task.taskKey) == nil else { continue }
            taskQueue.append(task)
        }
        scheduleNext()
    }

    public func insertTask(_ task: PlayerPreloadTask, at index: Int) {
        guard self.task(forKey: task.taskKey) == nil else { return }
        let idx = min(index, taskQueue.count)
        taskQueue.insert(task, at: idx)
        scheduleNext()
    }

    public func removeTask(forKey key: String) {
        taskQueue.removeAll { $0.taskKey == key }
        if let active = activeTasks.removeValue(forKey: key) {
            (active as? PlayerPreloadTaskImpl)?.cancel()
        }
    }

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

    public func cancelAllTasks() {
        removeAllTasks()
    }

    public func pause() {
        isPaused = true
    }

    public func resume() {
        isPaused = false
        scheduleNext()
    }

    public func task(forKey key: String) -> PlayerPreloadTask? {
        if let active = activeTasks[key] { return active }
        return taskQueue.first { $0.taskKey == key }
    }

    public var pendingTasks: [PlayerPreloadTask] {
        taskQueue.filter { $0.state == .pending }
    }

    public var loadingTasks: [PlayerPreloadTask] {
        Array(activeTasks.values)
    }

    private func scheduleNext() {
        guard !isPaused else { return }
        while activeTasks.count < maxConcurrentCount, let next = nextPendingTask() {
            startTask(next)
        }
    }

    private func nextPendingTask() -> PlayerPreloadTask? {
        guard let idx = taskQueue.firstIndex(where: { $0.state == .pending }) else { return nil }
        return taskQueue.remove(at: idx)
    }

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
