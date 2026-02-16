import Foundation
import UIKit
import AVFoundation

@MainActor
public final class PlayerPreRenderManagerPlugin: BasePlugin, PlayerPreRenderManagerService {

    private var entries: [String: PreRenderEntry] = [:]
    private var timeoutTimers: [String: Timer] = [:]
    private var _maxPreRenderCount: Int = 3
    private var _preRenderTimeout: TimeInterval = 10.0
    private var enginePool: PlayerEnginePoolService?
    private var _poolIdentifier: String = "default"

    public var maxPreRenderCount: Int {
        get { _maxPreRenderCount }
        set { _maxPreRenderCount = max(1, newValue) }
    }

    public var preRenderTimeout: TimeInterval {
        get { _preRenderTimeout }
        set { _preRenderTimeout = max(1, newValue) }
    }

    public var activeEntries: [PreRenderEntry] {
        Array(entries.values)
    }

    public required override init() {
        super.init()
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? PlayerPreRenderManagerConfigModel else { return }
        enginePool = model.enginePool
        _poolIdentifier = model.poolIdentifier
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        NotificationCenter.default.removeObserver(self)
        cancelAll()
    }

    // MARK: - PlayerPreRenderManagerService

    public func preRender(url: URL, identifier: String) {
        if entries[identifier] != nil {
            cancelPreRender(identifier: identifier)
        }

        guard entries.count < _maxPreRenderCount else {
            evictOldest()
            guard entries.count < _maxPreRenderCount else { return }
            return
        }

        var entry = PreRenderEntry(url: url, identifier: identifier)
        entry.state = .preparing

        let player = Player(name: "PreRender_\(identifier)")
        if let managerCtx = self.context as? Context {
            managerCtx.addExtendContext(player.context)
        }
        if let pool = enginePool {
            player.bindPool(pool, identifier: _poolIdentifier)
            player.acquireEngine()
        }
        entry.player = player

        entries[identifier] = entry

        player.engineService?.setURL(url)
        player.engineService?.volume = 0
        player.engineService?.isLooping = true

        let entryCreated = entry.createTime
        PLog.preRenderStart(identifier, activeCount: entries.count)

        player.context.add(self, event: .playerReadyToPlaySticky, option: .execOnlyOnce) { [weak self, identifier, entryCreated] _, _ in
            guard let self = self else { return }
            guard var e = self.entries[identifier] else { return }
            let elapsed = Int(Date().timeIntervalSince(entryCreated) * 1000)
            PLog.preRenderReadyToPlay(identifier, elapsedMs: elapsed)
            e.state = .readyToPlay
            self.entries[identifier] = e
            self.cancelTimeout(identifier: identifier)
            e.player?.engineService?.play()
        }

        player.context.add(self, event: .playerReadyForDisplaySticky, option: .execOnlyOnce) { [weak self, identifier, entryCreated] _, _ in
            guard let self = self else { return }
            guard var e = self.entries[identifier] else { return }
            let elapsed = Int(Date().timeIntervalSince(entryCreated) * 1000)
            PLog.preRenderReadyForDisplay(identifier, elapsedMs: elapsed)
            e.player?.engineService?.pause()
            e.player?.engineService?.avPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self = self else { return }
                    guard var entry = self.entries[identifier] else { return }
                    entry.state = .readyToDisplay
                    self.entries[identifier] = entry
                    let avRate = entry.player?.engineService?.avPlayer?.rate ?? -1
                    let layerRFD = entry.player?.engineService?.isReadyForDisplay ?? false
                    let timeCtrl = entry.player?.engineService?.avPlayer?.timeControlStatus.rawValue ?? -1
                    PLog.preRenderPauseState(identifier, avRate: avRate, layerRFD: layerRFD, timeControlStatus: "tc=\(timeCtrl)")
                    self.context?.post(.playerPreRenderReady, object: identifier as AnyObject, sender: self)
                }
            }
        }

        scheduleTimeout(identifier: identifier)

        context?.post(.playerPreRenderStarted, object: identifier as AnyObject, sender: self)
    }

    public func preRender(urls: [(url: URL, identifier: String)]) {
        for item in urls {
            preRender(url: item.url, identifier: item.identifier)
        }
    }

    public func cancelPreRender(identifier: String) {
        guard var entry = entries.removeValue(forKey: identifier) else { return }
        PLog.preRenderCancel(identifier, reason: "cancel_\(entry.state)")
        cancelTimeout(identifier: identifier)
        entry.state = .cancelled
        entry.player?.engineService?.stop()
        entry.player?.recycleEngine()
        if let playerCtx = entry.player?.context as? Context {
            playerCtx.removeFromBaseContext()
        }
    }

    public func cancelAll() {
        let ids = Array(entries.keys)
        for id in ids {
            cancelPreRender(identifier: id)
        }
    }

    public func consumePreRendered(identifier: String) -> Player? {
        guard let entry = entries[identifier] else {
            PLog.preRenderSkip(identifier, reason: "no_entry")
            return nil
        }
        guard entry.state == .readyToPlay || entry.state == .readyToDisplay else {
            PLog.preRenderSkip(identifier, reason: "state=\(entry.state)")
            return nil
        }
        PLog.preRenderConsume(identifier, state: "\(entry.state)")
        entries.removeValue(forKey: identifier)
        cancelTimeout(identifier: identifier)
        entry.player?.engineService?.pause()
        entry.player?.engineService?.avPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if let playerCtx = entry.player?.context as? Context {
            playerCtx.removeFromBaseContext()
        }
        return entry.player
    }

    public func takePlayer(identifier: String) -> Player? {
        guard let entry = entries.removeValue(forKey: identifier) else { return nil }
        PLog.preRenderTake(identifier, state: "\(entry.state)")
        cancelTimeout(identifier: identifier)
        entry.player?.engineService?.pause()
        entry.player?.engineService?.avPlayer?.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero)
        if let playerCtx = entry.player?.context as? Context {
            playerCtx.removeFromBaseContext()
        }
        return entry.player
    }

    public func isPreRendered(identifier: String) -> Bool {
        guard let state = entries[identifier]?.state else { return false }
        return state == .readyToPlay || state == .readyToDisplay
    }

    public func state(for identifier: String) -> PreRenderState {
        entries[identifier]?.state ?? .idle
    }

    // MARK: - Eviction

    private func evictOldest() {
        var oldestId: String?
        var oldestTime = Date.distantFuture

        for (id, entry) in entries {
            if entry.createTime < oldestTime {
                oldestTime = entry.createTime
                oldestId = id
            }
        }

        if let id = oldestId {
            cancelPreRender(identifier: id)
        }
    }

    // MARK: - Timeout

    private func scheduleTimeout(identifier: String) {
        timeoutTimers[identifier]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: _preRenderTimeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleTimeout(identifier: identifier)
            }
        }
        timeoutTimers[identifier] = timer
    }

    private func cancelTimeout(identifier: String) {
        timeoutTimers[identifier]?.invalidate()
        timeoutTimers.removeValue(forKey: identifier)
    }

    private func handleTimeout(identifier: String) {
        guard var entry = entries[identifier] else { return }
        if entry.state == .preparing {
            entry.state = .expired
            entries[identifier] = entry
            cancelPreRender(identifier: identifier)
            context?.post(.playerPreRenderTimeout, object: identifier as AnyObject, sender: self)
        }
    }

    // MARK: - Notifications

    @objc private func appDidEnterBackground() {
        cancelAll()
    }

    @objc private func didReceiveMemoryWarning() {
        cancelAll()
    }
}
