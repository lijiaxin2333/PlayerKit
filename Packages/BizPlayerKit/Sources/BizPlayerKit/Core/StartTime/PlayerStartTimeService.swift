import Foundation

// MARK: - StartTime Events

public extension Event {
    /// 起始时间已解析
    static let playerStartTimeDidResolve: Event = "PlayerStartTimeDidResolve"
}

// MARK: - Protocols

@MainActor
/// 起播时间修改器协议
public protocol PlayerStartTimeSetter: AnyObject {
    /// 是否需要对当前起播时间进行修改
    func shouldModifyStartTime(current: TimeInterval) -> Bool
    /// 返回修改后的起播时间
    func modifiedStartTime() -> TimeInterval
}

@MainActor
/// 起播时间校验器协议
public protocol PlayerStartTimeGuard: AnyObject {
    /// 校验给定起播时间是否有效
    func isValidStartTime(_ time: TimeInterval) -> Bool
}

@MainActor
/// 起播时间服务协议
public protocol PlayerStartTimeService: PluginService {

    /// 当前配置的起播时间
    var startTime: TimeInterval { get }

    /// 设置起播时间
    func setStartTime(_ time: TimeInterval)

    /// 添加起播时间修改器
    func addSetter(_ setter: PlayerStartTimeSetter)

    /// 移除起播时间修改器
    func removeSetter(_ setter: PlayerStartTimeSetter)

    /// 添加起播时间校验器
    func addGuard(_ guard: PlayerStartTimeGuard)

    /// 移除起播时间校验器
    func removeGuard(_ guard: PlayerStartTimeGuard)

    /// 解析得到最终的起播时间
    func resolveStartTime() -> TimeInterval

    /// 是否启用播放进度缓存
    var cacheProgressEnabled: Bool { get set }

    /// 缓存当前播放进度
    func cacheCurrentProgress()

    /// 获取指定键的缓存进度
    func cachedProgress(forKey key: String) -> TimeInterval?

    /// 清除指定键的缓存进度
    func clearCachedProgress(forKey key: String)

    /// 清除所有缓存进度
    func clearAllCachedProgress()
}
