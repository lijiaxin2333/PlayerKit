import Foundation

@MainActor
public protocol PlayerStartTimeSetter: AnyObject {
    func shouldModifyStartTime(current: TimeInterval) -> Bool
    func modifiedStartTime() -> TimeInterval
}

@MainActor
public protocol PlayerStartTimeGuard: AnyObject {
    func isValidStartTime(_ time: TimeInterval) -> Bool
}

@MainActor
public protocol PlayerStartTimeService: CCLCompService {

    var startTime: TimeInterval { get }

    func setStartTime(_ time: TimeInterval)

    func addSetter(_ setter: PlayerStartTimeSetter)

    func removeSetter(_ setter: PlayerStartTimeSetter)

    func addGuard(_ guard: PlayerStartTimeGuard)

    func removeGuard(_ guard: PlayerStartTimeGuard)

    func resolveStartTime() -> TimeInterval

    var cacheProgressEnabled: Bool { get set }

    func cacheCurrentProgress()

    func cachedProgress(forKey key: String) -> TimeInterval?

    func clearCachedProgress(forKey key: String)

    func clearAllCachedProgress()
}
