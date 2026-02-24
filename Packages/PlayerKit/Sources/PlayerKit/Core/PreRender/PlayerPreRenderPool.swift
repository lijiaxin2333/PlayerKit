import Foundation
import AVFoundation

/// 预渲染池，管理预渲染的播放器引擎
@MainActor
public final class PlayerPreRenderPool {

    public static let shared = PlayerPreRenderPool()

    // MARK: - Properties

    public var config: PlayerPreRenderPoolConfig {
        didSet { updateConfig() }
    }

    public var count: Int { entries.count }

    public private(set) var statistics: PlayerPreRenderPoolStatistics = .init()

    private var entries: [String: PreRenderEntry] = [:]
    private var timeouts: [String: Timer] = [:]

    private struct PreRenderEntry {
        let url: URL
        let engine: PlayerEngineCoreService
        let createdAt: Date
        var completedAt: Date?
        var state: PlayerPreRenderState
    }

    // MARK: - Init

    public init(config: PlayerPreRenderPoolConfig = PlayerPreRenderPoolConfig()) {
        self.config = config
    }

    private func updateConfig() {
        while entries.count > config.maxCount {
            evictOldest()
        }
    }

    // MARK: - Operations

    public func preRender(url: URL, identifier: String, extraConfig: PlayerEngineCoreConfigModel?) {
        if entries[identifier] != nil {
            cancel(identifier: identifier)
        }

        if entries.count >= config.maxCount {
            evictOldest()
            guard entries.count < config.maxCount else { return }
        }

        // 从引擎池获取引擎
        let engineService: PlayerEngineCoreService
        if let pooled = PlayerEnginePool.shared.dequeue(identifier: config.poolIdentifier) {
            engineService = pooled
        } else {
            let player = Player(name: "PreRender_\(identifier)")
            player.bindPool(identifier: config.poolIdentifier)
            guard let engine = player.engineService else { return }
            engineService = engine
        }

        // 配置引擎
        let engineConfig = extraConfig ?? PlayerEngineCoreConfigModel()
        engineConfig.isLooping = true
        engineConfig.initialVolume = 0
        engineConfig.autoPlay = false
        (engineService as? BasePlugin)?.config(engineConfig)

        // 加载数据
        engineService.setURL(url)

        // 创建条目
        let entry = PreRenderEntry(
            url: url,
            engine: engineService,
            createdAt: Date(),
            completedAt: nil,
            state: .preparing
        )
        entries[identifier] = entry
        statistics.totalStarted += 1

        // 开始预渲染
        engineService.volume = 0
        engineService.play()

        // 监听就绪状态
        observeReadyState(identifier: identifier, engine: engineService)

        // 启动超时计时器
        scheduleTimeout(identifier: identifier)

    }

    public func cancel(identifier: String) {
        guard let entry = entries.removeValue(forKey: identifier) else { return }
        cancelTimeout(identifier: identifier)

        entry.engine.pause()
        entry.engine.replaceCurrentItem(with: nil)

        if entry.engine.canReuse {
            entry.engine.prepareForReuse()
            PlayerEnginePool.shared.enqueue(entry.engine, identifier: config.poolIdentifier)
        }

        statistics.totalCancelled += 1
    }

    public func cancelAll() {
        let identifiers = Array(entries.keys)
        for id in identifiers {
            cancel(identifier: id)
        }
        timeouts.values.forEach { $0.invalidate() }
        timeouts.removeAll()
    }

    public func consume(identifier: String) -> PlayerEngineCoreService? {
        guard let entry = entries[identifier] else { return nil }
        guard entry.state == .readyToPlay || entry.state == .readyToDisplay else { return nil }

        entries.removeValue(forKey: identifier)
        cancelTimeout(identifier: identifier)

        entry.engine.pause()
        entry.engine.avPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)

        statistics.totalConsumed += 1
        return entry.engine
    }

    public func consumeAndTransfer(identifier: String, to player: Player) -> Bool {
        guard let engine = consume(identifier: identifier) else { return false }

        if let currentURL = player.dataService?.dataModel.videoURL,
           engine.currentURL != currentURL {
            if engine.canReuse {
                engine.prepareForReuse()
                PlayerEnginePool.shared.enqueue(engine, identifier: config.poolIdentifier)
            }
            return false
        }

        // 转移引擎到目标 Player
        player.recycleEngine()
        player.context.detachInstance(for: PlayerEngineCoreService.self)
        guard let enginePlugin = engine as? BasePlugin else { return false }
        player.context.registerInstance(enginePlugin, protocol: PlayerEngineCoreService.self)
        engine.volume = 1.0
        return true
    }

    // MARK: - Query

    public func state(for identifier: String) -> PlayerPreRenderState {
        entries[identifier]?.state ?? .idle
    }

    public func entry(for identifier: String) -> PlayerPreRenderEntry? {
        guard let e = entries[identifier] else { return nil }
        return PlayerPreRenderEntry(
            identifier: identifier,
            url: e.url,
            state: e.state,
            createdAt: e.createdAt,
            completedAt: e.completedAt
        )
    }

    public func allEntries() -> [PlayerPreRenderEntry] {
        entries.map { id, e in
            PlayerPreRenderEntry(
                identifier: id,
                url: e.url,
                state: e.state,
                createdAt: e.createdAt,
                completedAt: e.completedAt
            )
        }
    }

    public func contains(identifier: String) -> Bool {
        entries[identifier] != nil
    }

    // MARK: - Range Management

    public func keepRange(_ range: ClosedRange<Int>, identifierPrefix: String) {
        let toCancel = entries.keys.filter { id in
            guard id.hasPrefix(identifierPrefix) else { return false }
            let suffix = id.replacingOccurrences(of: identifierPrefix + "_", with: "")
            guard let idx = Int(suffix) else { return false }
            return !range.contains(idx)
        }
        for id in toCancel {
            cancel(identifier: id)
        }
    }

    public func preRenderAdjacent(
        currentIndex: Int,
        urls: [URL],
        identifierPrefix: String,
        offsets: [Int] = [-1, 1, -2, 2]
    ) {
        keepRange((currentIndex - 2)...(currentIndex + 2), identifierPrefix: identifierPrefix)

        for offset in offsets {
            let idx = currentIndex + offset
            guard idx >= 0, idx < urls.count else { continue }
            let identifier = "\(identifierPrefix)_\(idx)"
            if state(for: identifier) == .idle {
                preRender(url: urls[idx], identifier: identifier, extraConfig: nil)
            }
        }
    }

    // MARK: - Private

    private func observeReadyState(identifier: String, engine: PlayerEngineCoreService) {
        var observer: NSKeyValueObservation?
        observer = engine.avPlayer?.observe(\.status, options: [.new, .initial]) { [weak self] player, _ in
            guard let self = self else { return }
            MainActor.assumeIsolated {
                guard player.status == .readyToPlay else { return }
                self.markReady(identifier: identifier)
                observer?.invalidate()
                observer = nil
            }
        }
    }

    private func markReady(identifier: String) {
        guard var entry = entries[identifier] else { return }
        let elapsedMs = Int(Date().timeIntervalSince(entry.createdAt) * 1000)
        entry.state = .readyToPlay
        entry.completedAt = Date()
        entries[identifier] = entry
        statistics.totalCompleted += 1
    }

    private func evictOldest() {
        guard let oldest = entries.min(by: { $0.value.createdAt < $1.value.createdAt }) else { return }
        cancel(identifier: oldest.key)
        statistics.totalEvictions += 1
    }

    private func scheduleTimeout(identifier: String) {
        timeouts[identifier]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: config.timeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleTimeout(identifier: identifier)
            }
        }
        timeouts[identifier] = timer
    }

    private func cancelTimeout(identifier: String) {
        timeouts[identifier]?.invalidate()
        timeouts.removeValue(forKey: identifier)
    }

    private func handleTimeout(identifier: String) {
        guard entries[identifier] != nil else { return }
        cancel(identifier: identifier)
        statistics.totalTimeouts += 1
    }
}

// MARK: - Player Extension

public extension Player {

    /// 从预渲染池消费并转移引擎
    func adoptFromPreRenderPool(identifier: String) -> Bool {
        guard let poolPlugin = context.resolveService(PlayerPreRenderPoolService.self) else { return false }
        return poolPlugin.consumeAndTransfer(identifier: identifier, to: self)
    }
}
