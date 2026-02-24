import Foundation

@MainActor
/**
 * 起播时间插件，支持设置起播位置、Setter/Guard 扩展及播放进度缓存
 */
public final class PlayerStartTimePlugin: BasePlugin, PlayerStartTimeService {

    /** 内部存储的起播时间 */
    private var _startTime: TimeInterval = 0
    /** 起播时间修改器列表 */
    private var setters: [PlayerStartTimeSetter] = []
    /** 起播时间校验器列表 */
    private var guards: [PlayerStartTimeGuard] = []
    /** 播放进度缓存，按 URL 键存储 */
    private var progressCache: [String: TimeInterval] = [:]

    /** 是否启用播放进度缓存 */
    public var cacheProgressEnabled: Bool = false

    /** 播放引擎服务，用于 seek 和获取当前播放信息 */
    @PlayerPlugin private var engine: PlayerEngineCoreService?

    public required init() {
        super.init()
    }

    /** 当前配置的起播时间 */
    public var startTime: TimeInterval { _startTime }

    /**
     * 设置起播时间
     */
    public func setStartTime(_ time: TimeInterval) {
        _startTime = time
    }

    /**
     * 添加起播时间修改器
     */
    public func addSetter(_ setter: PlayerStartTimeSetter) {
        guard !setters.contains(where: { $0 === setter }) else { return }
        setters.append(setter)
    }

    /**
     * 移除起播时间修改器
     */
    public func removeSetter(_ setter: PlayerStartTimeSetter) {
        setters.removeAll { $0 === setter }
    }

    /**
     * 添加起播时间校验器
     */
    public func addGuard(_ guard: PlayerStartTimeGuard) {
        guard !guards.contains(where: { $0 === `guard` }) else { return }
        guards.append(`guard`)
    }

    /**
     * 移除起播时间校验器
     */
    public func removeGuard(_ guard: PlayerStartTimeGuard) {
        guards.removeAll { $0 === `guard` }
    }

    /**
     * 综合 Setter 和 Guard 解析最终的起播时间
     */
    public func resolveStartTime() -> TimeInterval {
        var resolved = _startTime

        for setter in setters {
            if setter.shouldModifyStartTime(current: resolved) {
                resolved = setter.modifiedStartTime()
            }
        }

        for g in guards {
            if !g.isValidStartTime(resolved) {
                resolved = 0
                break
            }
        }

        return resolved
    }

    /**
     * 缓存当前视频的播放进度
     */
    public func cacheCurrentProgress() {
        guard cacheProgressEnabled, let engine = engine else { return }
        guard let url = engine.currentURL else { return }
        let key = url.absoluteString
        let time = engine.currentTime
        guard time > 1 else { return }
        progressCache[key] = time
    }

    /**
     * 获取指定键的缓存进度
     */
    public func cachedProgress(forKey key: String) -> TimeInterval? {
        progressCache[key]
    }

    /**
     * 清除指定键的缓存进度
     */
    public func clearCachedProgress(forKey key: String) {
        progressCache.removeValue(forKey: key)
    }

    /**
     * 清除所有缓存进度
     */
    public func clearAllCachedProgress() {
        progressCache.removeAll()
    }

    /**
     * 插件加载时监听就绪、播放结束和退到后台事件，实现自动 seek 和进度缓存
     */
    override public func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        context.add(self, event: .playerReadyToPlaySticky) { [weak self] _, _ in
            guard let self = self else { return }
            let time = self.resolveStartTime()
            if time > 0 {
                self.engine?.seek(to: time)
            }
        }

        context.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            self?.cacheCurrentProgress()
        }

        context.add(self, event: .playerAppDidResignActive) { [weak self] _, _ in
            self?.cacheCurrentProgress()
        }
    }
}
