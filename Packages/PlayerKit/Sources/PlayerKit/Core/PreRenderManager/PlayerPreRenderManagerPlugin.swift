import Foundation
import UIKit
import AVFoundation

/**
 * 预渲染管理器插件，管理多个视频的预渲染任务
 */
@MainActor
public final class PlayerPreRenderManagerPlugin: BasePlugin, PlayerPreRenderManagerService {

    /** 预渲染条目映射，按标识符索引 */
    private var entries: [String: PreRenderEntry] = [:]
    /** 超时计时器映射 */
    private var timeoutTimers: [String: Timer] = [:]
    /** 最大预渲染数量 */
    private var _maxPreRenderCount: Int = 3
    /** 预渲染超时时间 */
    private var _preRenderTimeout: TimeInterval = 10.0
    /** 引擎池服务 */
    private var enginePool: PlayerEnginePoolService?
    /** 池标识符 */
    private var _poolIdentifier: String = "default"

    /** 最大预渲染数量（至少为 1） */
    public var maxPreRenderCount: Int {
        get { _maxPreRenderCount }
        set { _maxPreRenderCount = max(1, newValue) }
    }

    /** 预渲染超时时间（至少为 1 秒） */
    public var preRenderTimeout: TimeInterval {
        get { _preRenderTimeout }
        set { _preRenderTimeout = max(1, newValue) }
    }

    /** 当前所有活动预渲染条目 */
    public var activeEntries: [PreRenderEntry] {
        Array(entries.values)
    }

    /**
     * 初始化插件
     */
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

    /**
     * 预渲染指定 URL
     */
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

        let engineConfig = PlayerEngineCoreConfigModel()
        engineConfig.isLooping = true
        engineConfig.initialVolume = 0
        player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: engineConfig)

        let dataConfig = PlayerDataConfigModel()
        dataConfig.initialDataModel = PlayerDataModel(videoURL: url)
        player.dataService?.config(dataConfig)

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

    /**
     * 批量预渲染多个 URL
     */
    public func preRender(urls: [(url: URL, identifier: String)]) {
        for item in urls {
            preRender(url: item.url, identifier: item.identifier)
        }
    }

    /**
     * 取消指定标识符的预渲染
     */
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

    /**
     * 取消所有预渲染
     */
    public func cancelAll() {
        let ids = Array(entries.keys)
        for id in ids {
            cancelPreRender(identifier: id)
        }
    }

    /**
     * 消费预渲染好的播放器（不移除条目，调用方负责管理）
     */
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

    /**
     * 取出预渲染好的播放器（移除条目）
     */
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

    /**
     * 检查指定标识符是否已预渲染完成
     */
    public func isPreRendered(identifier: String) -> Bool {
        guard let state = entries[identifier]?.state else { return false }
        return state == .readyToPlay || state == .readyToDisplay
    }

    /**
     * 获取指定标识符的预渲染状态
     */
    public func state(for identifier: String) -> PreRenderState {
        entries[identifier]?.state ?? .idle
    }

    /**
     * 驱逐最早的预渲染条目
     */
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

    /**
     * 安排超时计时器
     */
    private func scheduleTimeout(identifier: String) {
        timeoutTimers[identifier]?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: _preRenderTimeout, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handleTimeout(identifier: identifier)
            }
        }
        timeoutTimers[identifier] = timer
    }

    /**
     * 取消超时计时器
     */
    private func cancelTimeout(identifier: String) {
        timeoutTimers[identifier]?.invalidate()
        timeoutTimers.removeValue(forKey: identifier)
    }

    /**
     * 处理超时
     */
    private func handleTimeout(identifier: String) {
        guard var entry = entries[identifier] else { return }
        if entry.state == .preparing {
            entry.state = .expired
            entries[identifier] = entry
            cancelPreRender(identifier: identifier)
            context?.post(.playerPreRenderTimeout, object: identifier as AnyObject, sender: self)
        }
    }

    /**
     * 应用进入后台时取消所有预渲染
     */
    @objc private func appDidEnterBackground() {
        cancelAll()
    }

    /**
     * 收到内存警告时取消所有预渲染
     */
    @objc private func didReceiveMemoryWarning() {
        cancelAll()
    }
}
