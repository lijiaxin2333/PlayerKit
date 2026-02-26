import Foundation
import AVFoundation
import UIKit
import KTVHTTPCache

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
    private var observers: [String: EntryObservers] = [:]
    private let hostContainerView = UIView(frame: CGRect(x: -2000, y: -2000, width: 1, height: 1))

    private struct PreRenderEntry {
        let url: URL
        let avPlayer: AVPlayer
        let renderView: PlayerEngineRenderView
        let createdAt: Date
        var completedAt: Date?
        var state: PlayerPreRenderState
    }

    private struct EntryObservers {
        var status: NSKeyValueObservation?
        var readyForDisplay: NSKeyValueObservation?
    }

    // MARK: - Init

    public init(config: PlayerPreRenderPoolConfig = PlayerPreRenderPoolConfig()) {
        self.config = config
        hostContainerView.clipsToBounds = true
        hostContainerView.isUserInteractionEnabled = false
        hostContainerView.backgroundColor = .black
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

        let core = makeCore(url: url, extraConfig: extraConfig)
        guard let core else { return }

        let entry = PreRenderEntry(
            url: url,
            avPlayer: core.player,
            renderView: core.renderView,
            createdAt: Date(),
            completedAt: nil,
            state: .preparing
        )
        entries[identifier] = entry
        statistics.totalStarted += 1

        observeReadyState(identifier: identifier, player: core.player, renderView: core.renderView)
        scheduleTimeout(identifier: identifier)
        // 不再需要 play()，preroll 会在 readyToPlay 后自动调用
    }

    public func cancel(identifier: String) {
        guard let entry = entries.removeValue(forKey: identifier) else { return }
        clearRuntime(identifier: identifier)
        releaseCore(avPlayer: entry.avPlayer, renderView: entry.renderView)
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
        guard let state = entries[identifier]?.state,
              state == .readyToPlay || state == .readyToDisplay else { return nil }
        guard let entry = entries.removeValue(forKey: identifier) else { return nil }

        clearRuntime(identifier: identifier)
        entry.avPlayer.pause()
        // preroll 不会移动播放位置，不需要 seek 回 0
        entry.renderView.removeFromSuperview()

        let engine = PlayerEngineCorePlugin()
        engine.adoptPreparedCore(player: entry.avPlayer, renderView: entry.renderView, url: entry.url)

        statistics.totalConsumed += 1
        return engine
    }

    public func consumeAndTransfer(identifier: String, to player: Player) -> Bool {
        guard let state = entries[identifier]?.state,
              state == .readyToPlay || state == .readyToDisplay else { return false }
        guard let entry = entries.removeValue(forKey: identifier) else { return false }
        clearRuntime(identifier: identifier)
        entry.avPlayer.pause()
        // preroll 不会移动播放位置，不需要 seek 回 0
        entry.renderView.removeFromSuperview()

        if let currentURL = player.dataService?.dataModel.videoURL,
           entry.url != currentURL {
            releaseCore(avPlayer: entry.avPlayer, renderView: entry.renderView)
            return false
        }

        guard let engine = player.engineService as? PlayerEngineCorePlugin else {
            releaseCore(avPlayer: entry.avPlayer, renderView: entry.renderView)
            return false
        }
        engine.adoptPreparedCore(player: entry.avPlayer, renderView: entry.renderView, url: entry.url)
        engine.volume = 1.0
        engine.isLooping = false
        engine.pause()
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

    private struct CreatedCore {
        let player: AVPlayer
        let renderView: PlayerEngineRenderView
    }

    private func makeCore(url: URL, extraConfig: PlayerEngineCoreConfigModel?) -> CreatedCore? {
        let player = AVPlayer()
        let renderView = PlayerEngineRenderView(frame: hostContainerView.bounds)
        renderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        renderView.setPlayer(player)
        renderView.isHidden = false
        attachRenderViewToHost(renderView)

        let engineConfig = extraConfig ?? PlayerEngineCoreConfigModel()
        player.actionAtItemEnd = engineConfig.isLooping ? .none : .pause
        player.automaticallyWaitsToMinimizeStalling = false
        // preroll 不需要设置 rate，会预热管线但不会播放

        let finalURL = proxyURL(for: url)
        let asset = AVURLAsset(url: finalURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        let item = AVPlayerItem(asset: asset)
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        player.replaceCurrentItem(with: item)
        return CreatedCore(player: player, renderView: renderView)
    }

    private func observeReadyState(identifier: String, player: AVPlayer, renderView: PlayerEngineRenderView) {
        var statusObservation: NSKeyValueObservation?
        statusObservation = player.observe(\.status, options: [.new, .initial]) { [weak self] observed, _ in
            guard let self = self else { return }
            MainActor.assumeIsolated {
                guard observed.status == .readyToPlay else { return }
                self.markReadyToPlay(identifier: identifier)
                statusObservation?.invalidate()
                statusObservation = nil
                // readyToPlay 后开始 preroll 预热管线
                self.startPreroll(identifier: identifier, player: player, renderView: renderView)
            }
        }

        var displayObservation: NSKeyValueObservation?
        displayObservation = renderView.playerLayer.observe(\.isReadyForDisplay, options: [.new, .initial]) { [weak self] layer, _ in
            guard let self = self else { return }
            let isReady = layer.isReadyForDisplay
            MainActor.assumeIsolated {
                guard isReady else { return }
                self.markReadyToDisplay(identifier: identifier)
                displayObservation?.invalidate()
                displayObservation = nil
            }
        }
        observers[identifier] = EntryObservers(status: statusObservation, readyForDisplay: displayObservation)
    }

    private func startPreroll(identifier: String, player: AVPlayer, renderView: PlayerEngineRenderView) {
        player.preroll(atRate: 1.0) { [weak self] finished in
            MainActor.assumeIsolated {
                guard let self = self, finished else { return }
                // preroll 完成，管线已预热
                // 如果 AVPlayerLayer 在视图层级中，isReadyForDisplay 会变成 true
                if renderView.playerLayer.isReadyForDisplay {
                    self.markReadyToDisplay(identifier: identifier)
                }
            }
        }
    }

    private func markReadyToPlay(identifier: String) {
        guard var entry = entries[identifier] else { return }
        if entry.state == .preparing {
            entry.state = .readyToPlay
        }
        if entry.completedAt == nil {
            entry.completedAt = Date()
            statistics.totalCompleted += 1
        }
        entries[identifier] = entry
    }

    private func markReadyToDisplay(identifier: String) {
        guard var entry = entries[identifier] else { return }
        entry.state = .readyToDisplay
        if entry.completedAt == nil {
            entry.completedAt = Date()
            statistics.totalCompleted += 1
        }
        entries[identifier] = entry
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

    private func clearRuntime(identifier: String) {
        cancelTimeout(identifier: identifier)
        observers[identifier]?.status?.invalidate()
        observers[identifier]?.readyForDisplay?.invalidate()
        observers.removeValue(forKey: identifier)
    }

    private func handleTimeout(identifier: String) {
        guard entries[identifier] != nil else { return }
        cancel(identifier: identifier)
        statistics.totalTimeouts += 1
    }

    private func releaseCore(avPlayer: AVPlayer, renderView: PlayerEngineRenderView) {
        avPlayer.pause()
        avPlayer.replaceCurrentItem(with: nil)
        renderView.removeFromSuperview()
    }

    private func attachRenderViewToHost(_ renderView: PlayerEngineRenderView) {
        ensureHostContainer()
        guard hostContainerView.superview != nil else { return }
        renderView.removeFromSuperview()
        renderView.frame = hostContainerView.bounds
        hostContainerView.addSubview(renderView)
    }

    private func reattachAllRenderViewsToHost() {
        ensureHostContainer()
        guard hostContainerView.superview != nil else { return }
        for entry in entries.values {
            if entry.renderView.superview !== hostContainerView {
                entry.renderView.removeFromSuperview()
                entry.renderView.frame = hostContainerView.bounds
                hostContainerView.addSubview(entry.renderView)
            }
        }
    }

    private func ensureHostContainer() {
        if hostContainerView.superview != nil {
            return
        }
        guard UIApplication.shared.applicationState == .active else { return }
        guard let window = activeKeyWindow() else { return }
        hostContainerView.frame = CGRect(x: -2000, y: -2000, width: 1, height: 1)
        window.addSubview(hostContainerView)
    }

    private func activeKeyWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes where scene.activationState == .foregroundActive {
            if let key = scene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
            if let first = scene.windows.first {
                return first
            }
        }
        return nil
    }

    private func proxyURL(for original: URL) -> URL {
        guard let scheme = original.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return original
        }
        return KTVHTTPCache.proxyURL(withOriginalURL: original) ?? original
    }
}

// MARK: - Player Extension

public extension Player {

    /// 从预渲染池消费并转移引擎
    func adoptFromPreRenderPool(identifier: String) -> Bool {
        guard let poolPlugin = preRenderPoolService else { return false }
        return poolPlugin.consumeAndTransfer(identifier: identifier, to: self)
    }
}
