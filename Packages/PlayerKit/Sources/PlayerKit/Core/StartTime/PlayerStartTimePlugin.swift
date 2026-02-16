import Foundation

@MainActor
public final class PlayerStartTimePlugin: BasePlugin, PlayerStartTimeService {

    private var _startTime: TimeInterval = 0
    private var setters: [PlayerStartTimeSetter] = []
    private var guards: [PlayerStartTimeGuard] = []
    private var progressCache: [String: TimeInterval] = [:]

    public var cacheProgressEnabled: Bool = false

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engine: PlayerEngineCoreService?

    public required override init() {
        super.init()
    }

    public var startTime: TimeInterval { _startTime }

    public func setStartTime(_ time: TimeInterval) {
        _startTime = time
    }

    public func addSetter(_ setter: PlayerStartTimeSetter) {
        guard !setters.contains(where: { $0 === setter }) else { return }
        setters.append(setter)
    }

    public func removeSetter(_ setter: PlayerStartTimeSetter) {
        setters.removeAll { $0 === setter }
    }

    public func addGuard(_ guard: PlayerStartTimeGuard) {
        guard !guards.contains(where: { $0 === `guard` }) else { return }
        guards.append(`guard`)
    }

    public func removeGuard(_ guard: PlayerStartTimeGuard) {
        guards.removeAll { $0 === `guard` }
    }

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

    public func cacheCurrentProgress() {
        guard cacheProgressEnabled, let engine = engine else { return }
        guard let url = engine.currentURL else { return }
        let key = url.absoluteString
        let time = engine.currentTime
        guard time > 1 else { return }
        progressCache[key] = time
    }

    public func cachedProgress(forKey key: String) -> TimeInterval? {
        progressCache[key]
    }

    public func clearCachedProgress(forKey key: String) {
        progressCache.removeValue(forKey: key)
    }

    public func clearAllCachedProgress() {
        progressCache.removeAll()
    }

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
