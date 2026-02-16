import Foundation

public enum PlayerPreloadTaskType: Int {
    case video = 0
    case audio
    case cover
}

public enum PlayerPreloadTaskState: Int {
    case pending = 0
    case loading
    case finished
    case cancelled
    case failed
}

@MainActor
public protocol PlayerPreloadTask: AnyObject {
    var taskKey: String { get }
    var taskType: PlayerPreloadTaskType { get }
    var url: URL { get }
    var preloadSize: Int64 { get }
    var priority: Int { get set }
    var state: PlayerPreloadTaskState { get }
}

@MainActor
public protocol PlayerPreloadService: PluginService {

    var maxConcurrentCount: Int { get set }

    var isPaused: Bool { get }

    func addTask(_ task: PlayerPreloadTask)

    func addTasks(_ tasks: [PlayerPreloadTask])

    func insertTask(_ task: PlayerPreloadTask, at index: Int)

    func removeTask(forKey key: String)

    func removeAllTasks()

    func cancelTask(forKey key: String)

    func cancelAllTasks()

    func pause()

    func resume()

    func task(forKey key: String) -> PlayerPreloadTask?

    var pendingTasks: [PlayerPreloadTask] { get }

    var loadingTasks: [PlayerPreloadTask] { get }
}
