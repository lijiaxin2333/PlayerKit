//
//  PlayerEngineCorePlugin.swift
//  playerkit
//
//  Core 播放引擎组件实现（基于 AVPlayer）
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 播放器视图

/**
 * 基于 AVPlayerLayer 的播放器渲染视图
 */
public class PlayerEngineRenderView: UIView {

    /**
     * 指定底层使用 AVPlayerLayer
     */
    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    /**
     * AVPlayerLayer 的便捷访问
     */
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    /**
     * 持有的 AVPlayer 引用
     */
    private var playerRef: AVPlayer?
    /**
     * 监听 isReadyForDisplay 的 KVO
     */
    private var displayObservation: NSKeyValueObservation?
    /**
     * 首次准备好显示时的回调
     */
    var onReadyForDisplay: (() -> Void)?

    /**
     * 取消对显示就绪状态的监听
     */
    func cancelDisplayObservation() {
        displayObservation?.invalidate()
        displayObservation = nil
    }

    /**
     * 重新监听 isReadyForDisplay
     */
    func reobserveReadyForDisplay() {
        displayObservation?.invalidate()
        displayObservation = nil
        if playerLayer.isReadyForDisplay {
            onReadyForDisplay?()
            return
        }
        displayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] _, change in
            guard change.newValue == true else { return }
            self?.displayObservation?.invalidate()
            self?.displayObservation = nil
            self?.onReadyForDisplay?()
        }
    }

    /**
     * 设置要绑定的 AVPlayer
     */
    func setPlayer(_ player: AVPlayer?) {
        playerRef = player
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        displayObservation?.invalidate()
        displayObservation = nil
        if playerLayer.isReadyForDisplay {
            onReadyForDisplay?()
        } else {
            displayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] _, change in
                guard change.newValue == true else { return }
                self?.displayObservation?.invalidate()
                self?.displayObservation = nil
                self?.onReadyForDisplay?()
            }
        }
    }

    /**
     * 确保 player 已正确绑定到 layer
     */
    public func ensurePlayerBound() {
        guard let player = playerRef else { return }
        if playerLayer.player !== player {
            playerLayer.player = player
        }
        playerLayer.frame = bounds
    }

    /**
     * 视图加入窗口时重新绑定
     */
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            ensurePlayerBound()
        }
    }

    /**
     * 布局变化时同步 layer 尺寸
     */
    override public func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - 播放引擎组件

/**
 * 基于 AVPlayer 的播放引擎核心插件
 */
@MainActor
public final class PlayerEngineCorePlugin: BasePlugin, PlayerEngineCoreService {

    public typealias ConfigModelType = PlayerEngineCoreConfigModel

    // MARK: - Properties

    /**
     * AVPlayer 实例
     */
    private var avPlayerInstance: AVPlayer?
    /**
     * 当前播放项
     */
    private var playerItem: AVPlayerItem?
    /**
     * 渲染视图
     */
    private var renderView: PlayerEngineRenderView?
    /**
     * 外部添加的周期时间观察者
     */
    private var timeObservers: [String: Any] = [:]
    /**
     * 播放状态观察者
     */
    private var playbackObserver: NSObjectProtocol?
    /**
     * 内部时间更新观察者
     */
    private var timeObserver: Any?
    /**
     * 监听 isPlaybackLikelyToKeepUp
     */
    private var keepUpObserver: NSKeyValueObservation?
    /**
     * 监听 isPlaybackBufferEmpty
     */
    private var bufferEmptyObserver: NSKeyValueObservation?
    /**
     * 监听 loadedTimeRanges
     */
    private var loadedRangesObserver: NSKeyValueObservation?
    /**
     * 卡顿重试次数
     */
    private var stalledRetryCount: Int = 0
    /**
     * 是否已从卡顿恢复过
     */
    private var hasResumedFromBuffer: Bool = false
    /**
     * 重试定时器
     */
    private var retryTimer: Timer?
    /**
     * 网络恢复监听
     */
    private var networkObserver: NSObjectProtocol?
    /**
     * 最大重试次数
     */
    private static let maxRetryCount = 3

    /**
     * 播放状态
     */
    private var _playbackState: PlayerPlaybackState = .stopped
    /**
     * 加载状态
     */
    private var _loadState: PlayerLoadState = .idle
    /**
     * 视频缩放模式
     */
    private var _scalingMode: PlayerScalingMode = .fill
    /**
     * 播放倍速
     */
    private var _rate: Float = 1.0

    /**
     * 是否处于回收复用流程
     */
    public private(set) var isRecycling: Bool = false
    /**
     * 是否可复用
     */
    public var canReuse: Bool { avPlayerInstance != nil && !isRecycling }

    // MARK: - PlayerEngineCoreService

    /**
     * 底层 AVPlayer
     */
    public var avPlayer: AVPlayer? { avPlayerInstance }
    /**
     * 播放器视图
     */
    public var playerView: UIView? { renderView }
    /**
     * 当前播放 URL
     */
    public var currentURL: URL?

    /**
     * 播放状态
     */
    public var playbackState: PlayerPlaybackState {
        get { _playbackState }
        set {
            guard _playbackState != newValue else { return }
            _playbackState = newValue
            context?.post(.playerPlaybackStateChanged, object: _playbackState, sender: self)
        }
    }

    /**
     * 加载状态
     */
    public var loadState: PlayerLoadState {
        get { _loadState }
        set {
            guard _loadState != newValue else { return }
            _loadState = newValue
            context?.post(.playerLoadStateDidChange, object: _loadState, sender: self)
        }
    }

    /**
     * 当前播放时间（秒）
     */
    public var currentTime: TimeInterval {
        guard let time = avPlayerInstance?.currentTime() else { return 0 }
        return CMTimeGetSeconds(time)
    }

    /**
     * 总时长（秒）
     */
    public var duration: TimeInterval {
        guard let playerItem = playerItem,
              playerItem.duration.isNumeric else { return 0 }
        return CMTimeGetSeconds(playerItem.duration)
    }

    /**
     * 缓冲进度（0-1）
     */
    public var bufferProgress: Double {
        guard let playerItem = playerItem else { return 0 }
        let currentTime = self.currentTime
        let bufferedTime = loadedTimeRanges(of: playerItem)
        let duration = self.duration

        if duration > 0 && bufferedTime > currentTime {
            return min(1.0, bufferedTime / duration)
        }
        return 0
    }

    /**
     * 首帧是否已显示
     */
    public var isReadyForDisplay: Bool {
        renderView?.playerLayer.isReadyForDisplay ?? false
    }

    /**
     * 播放倍速
     */
    public var rate: Float {
        get { _rate }
        set {
            _rate = newValue
            if playbackState == .playing {
                avPlayerInstance?.rate = newValue
            }
        }
    }

    /**
     * 是否循环播放
     */
    public var isLooping: Bool = false {
        didSet {
            if isLooping {
                avPlayerInstance?.actionAtItemEnd = .none
            } else {
                avPlayerInstance?.actionAtItemEnd = .pause
            }
            context?.post(.playerLoopingDidChange, object: isLooping, sender: self)
        }
    }

    /**
     * 音量（0-1）
     */
    public var volume: Float {
        get { avPlayerInstance?.volume ?? 1.0 }
        set {
            avPlayerInstance?.volume = newValue
            context?.post(.playerVolumeDidChange, object: newValue, sender: self)
        }
    }

    /**
     * 视频缩放模式
     */
    public var scalingMode: PlayerScalingMode {
        get { _scalingMode }
        set {
            _scalingMode = newValue
            switch newValue {
            case .fit:
                renderView?.playerLayer.videoGravity = .resizeAspect
            case .fill:
                renderView?.playerLayer.videoGravity = .resizeAspectFill
            case .fillEdge:
                renderView?.playerLayer.videoGravity = .resize
            }
        }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    deinit {
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        createPlayerIfNeeded()

        (self.context as? Context)?.bindStickyEvent(.playerEngineDidCreateSticky, value: self)
        self.context?.post(.playerEngineDidCreateSticky, object: self, sender: self)
    }

    /**
     * 插件即将卸载
     */
    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        cleanup()
    }

    // MARK: - Configuration

    /**
     * 应用配置模型
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerEngineCoreConfigModel else { return }

        isLooping = config.isLooping
        scalingMode = config.scalingMode

        if let player = avPlayerInstance {
            player.volume = config.initialVolume
        }

        if config.autoPlay {
            _ = context?.add(self, event: .playerReadyToPlaySticky, option: .execOnlyOnce) { [weak self] _, _ in
                self?.play()
            }
        }
    }

    // MARK: - Methods

    /**
     * 设置 URL 的时间戳（用于统计）
     */
    private var setURLTime: CFAbsoluteTime = 0

    /**
     * 设置播放 URL
     */
    public func setURL(_ url: URL) {
        self.currentURL = url
        stalledRetryCount = 0
        cancelRetry()
        setURLTime = CFAbsoluteTimeGetCurrent()
        PLog.engineSetURL(url.absoluteString, playerName: (self.context as? Context)?.name ?? "?")
        (self.context as? Context)?.bindStickyEvent(.playerReadyForDisplaySticky, value: nil)
        (self.context as? Context)?.bindStickyEvent(.playerReadyToPlaySticky, value: nil)
        createPlayerIfNeeded()
        removePlaybackObservers()

        let prefetchService = context?.tryResolveService(PlayerPrefetchService.self)
        prefetchService?.prioritize(url: url)
        let finalURL = prefetchService?.proxyURL(for: url) ?? url
        let asset = AVURLAsset(url: finalURL, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false
        ])
        let item = AVPlayerItem(asset: asset)
        item.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        replaceCurrentItem(with: item)
    }

    /**
     * 准备播放
     */
    public func prepareToPlay() {
        createPlayerIfNeeded()
        loadState = .preparing
    }

    /**
     * 开始播放
     */
    public func play() {
        guard let player = avPlayerInstance else { return }
        if let item = player.currentItem {
            item.preferredForwardBufferDuration = 0
        }
        hasResumedFromBuffer = false
        let targetRate = _rate > 0 ? _rate : 1.0
        player.play()
        player.rate = targetRate
        playbackState = .playing
        observeBufferState()
    }

    /**
     * 暂停播放
     */
    public func pause() {
        removeBufferObservers()
        avPlayerInstance?.pause()
        playbackState = .paused
    }

    /**
     * 停止播放
     */
    public func stop() {
        removeBufferObservers()
        avPlayerInstance?.pause()
        avPlayerInstance?.seek(to: .zero)
        playbackState = .stopped
    }

    /**
     * Seek 到指定时间
     */
    public func seek(to time: TimeInterval) {
        seek(to: time, completion: nil)
    }

    /**
     * Seek 到指定时间并回调
     */
    public func seek(to time: TimeInterval, completion: ((Bool) -> Void)?) {
        guard let player = avPlayerInstance, duration > 0 else {
            completion?(false)
            return
        }

        let targetTime = CMTime(seconds: min(max(time, 0), duration), preferredTimescale: 600)
        let stateBeforeSeek = _playbackState
        playbackState = .seeking

        context?.post(.playerSeekBegin, object: time, sender: self)

        player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let self = self else { return }
            if finished {
                let restoredState: PlayerPlaybackState = (stateBeforeSeek == .playing) ? .playing : .paused
                self.playbackState = restoredState
                self.context?.post(.playerSeekEnd, object: time, sender: self)
            }
            completion?(finished)
        }
    }

    /**
     * 添加周期时间观察者
     */
    public func addPeriodicTimeObserver(interval: TimeInterval, queue: DispatchQueue, block: @escaping (TimeInterval) -> Void) -> AnyObject? {
        guard let player = avPlayerInstance else { return nil }

        let time = CMTime(seconds: interval, preferredTimescale: 600)
        let observer = player.addPeriodicTimeObserver(forInterval: time, queue: queue) { time in
            block(CMTimeGetSeconds(time))
        }

        let key = UUID().uuidString
        timeObservers[key] = observer
        return TimeObserverToken(key: key, engine: self)
    }

    /**
     * 移除时间观察者
     */
    public func removeTimeObserver(_ observer: AnyObject?) {
        guard let token = observer as? TimeObserverToken else { return }
        if let obs = timeObservers.removeValue(forKey: token.key) {
            avPlayerInstance?.removeTimeObserver(obs)
        }
    }

    /**
     * 替换当前播放项
     */
    public func replaceCurrentItem(with item: AVPlayerItem?) {
        self.playerItem = item

        if let player = avPlayerInstance {
            player.replaceCurrentItem(with: item)

            if let item = item {
                loadState = .loading
                addPlaybackObservers(to: item)
                renderView?.reobserveReadyForDisplay()
            } else {
                loadState = .idle
                renderView?.cancelDisplayObservation()
            }

            context?.post(.playerEngineDidChange, sender: self)
        }
    }

    /**
     * 重置播放器
     */
    public func reset() {
        cleanup()
        createPlayer()
    }

    // MARK: - Reuse Lifecycle

    /**
     * 准备复用（进入回收池前）
     */
    public func prepareForReuse() {
        isRecycling = true
        removeBufferObservers()
        cancelRetry()
        avPlayerInstance?.pause()
        removePlaybackObservers()
        avPlayerInstance?.replaceCurrentItem(with: nil)
        playerItem = nil
        currentURL = nil
        _playbackState = .stopped
        _loadState = .idle
        volume = 0
        renderView?.isHidden = true
        renderView?.cancelDisplayObservation()
        (self.context as? Context)?.bindStickyEvent(.playerReadyForDisplaySticky, value: nil)
        (self.context as? Context)?.bindStickyEvent(.playerReadyToPlaySticky, value: nil)
    }

    /**
     * 从回收池出队时调用
     */
    public func didDequeueForReuse() {
        isRecycling = false
        createPlayerIfNeeded()
        avPlayerInstance?.automaticallyWaitsToMinimizeStalling = false
        volume = 1.0
        renderView?.isHidden = false
        renderView?.ensurePlayerBound()
    }

    // MARK: - Private Methods

    /**
     * 按需创建播放器
     */
    private func createPlayerIfNeeded() {
        if avPlayerInstance == nil {
            createPlayer()
        }
    }

    /**
     * 创建 AVPlayer 实例
     */
    private func createPlayer() {
        let newPlayer = AVPlayer()
        self.avPlayerInstance = newPlayer

        let readyForDisplayHandler: () -> Void = { [weak self] in
            guard let self = self else { return }
            let elapsed = Int((CFAbsoluteTimeGetCurrent() - self.setURLTime) * 1000)
            PLog.engineReadyForDisplay(elapsedMs: elapsed, playerName: (self.context as? Context)?.name ?? "?")
            (self.context as? Context)?.bindStickyEvent(.playerReadyForDisplaySticky, value: self)
            self.context?.post(.playerReadyForDisplaySticky, object: self, sender: self)
        }

        if let existing = renderView {
            existing.onReadyForDisplay = readyForDisplayHandler
            existing.setPlayer(newPlayer)
        } else {
            let rv = PlayerEngineRenderView(frame: .zero)
            rv.onReadyForDisplay = readyForDisplayHandler
            rv.setPlayer(newPlayer)
            self.renderView = rv
        }

        newPlayer.automaticallyWaitsToMinimizeStalling = false
        newPlayer.actionAtItemEnd = isLooping ? .none : .pause

        configureAudioSession()

        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let currentTime = CMTimeGetSeconds(time)
            self.context?.post(.playerTimeDidChange, object: currentTime, sender: self)
        }
    }

    /**
     * 配置音频会话
     */
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[PlayerEngineCorePlugin] 音频会话配置失败: \(error)")
        }
    }

    /**
     * 清理所有资源
     */
    private func cleanup() {
        removeBufferObservers()
        removePlaybackObservers()
        cancelRetry()

        if let observer = timeObserver {
            avPlayerInstance?.removeTimeObserver(observer)
            timeObserver = nil
        }

        timeObservers.values.forEach { observer in
            avPlayerInstance?.removeTimeObserver(observer)
        }
        timeObservers.removeAll()

        avPlayerInstance?.pause()
        avPlayerInstance?.replaceCurrentItem(with: nil)

        avPlayerInstance = nil
        playerItem = nil
        renderView = nil

        playbackState = .stopped
        loadState = .idle
    }

    /**
     * 为 AVPlayerItem 添加播放相关观察
     */
    private func addPlaybackObservers(to item: AVPlayerItem) {
        playbackObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            let status = item.status
            let duration = CMTimeGetSeconds(item.duration)
            let error = item.error
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                switch status {
                case .readyToPlay:
                    self.loadState = .ready
                    let elapsed = Int((CFAbsoluteTimeGetCurrent() - self.setURLTime) * 1000)
                    PLog.engineReadyToPlay(elapsedMs: elapsed, playerName: (self.context as? Context)?.name ?? "?")

                    if duration.isFinite {
                        self.context?.post(.playerDurationDidSet, object: duration, sender: self)
                    }

                    (self.context as? Context)?.bindStickyEvent(.playerReadyToPlaySticky, value: self)
                    self.context?.post(.playerReadyToPlaySticky, object: self, sender: self)

                case .failed:
                    let pName = (self.context as? Context)?.name ?? "?"
                    PLog.itemFailed(pName, error: error?.localizedDescription ?? "unknown")
                    self.stalledRetryCount += 1
                    if self.stalledRetryCount <= Self.maxRetryCount, let url = self.currentURL {
                        let delay = min(pow(2.0, Double(self.stalledRetryCount - 1)), 8.0)
                        PLog.itemRetry(pName)
                        self.scheduleRetry(url: url, delay: delay)
                    } else {
                        self.loadState = .failed
                        self.playbackState = .failed
                        self.observeNetworkForRecovery()
                        self.context?.post(.playerPlaybackDidFail, object: error, sender: self)
                    }

                case .unknown:
                    self.loadState = .preparing

                @unknown default:
                    break
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(_:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )
    }

    /**
     * 移除播放观察者
     */
    private func removePlaybackObservers() {
        if let item = playerItem {
            NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: item)
        }
        playbackObserver = nil
    }

    /**
     * 监听缓冲状态
     */
    private func observeBufferState() {
        removeBufferObservers()
        guard let item = avPlayerInstance?.currentItem else { return }
        let pName = (self.context as? Context)?.name ?? "?"

        keepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tryResumeIfStalled(source: "keepUp", playerName: pName)
            }
        }

        loadedRangesObserver = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tryResumeIfStalled(source: "loadedRanges", playerName: pName)
            }
        }

        bufferEmptyObserver = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                guard self._playbackState == .playing else { return }
                if item.isPlaybackBufferEmpty {
                    PLog.bufferEmpty(pName)
                }
            }
        }
    }

    /**
     * 尝试从卡顿恢复
     */
    private func tryResumeIfStalled(source: String, playerName: String) {
        guard _playbackState == .playing else { return }
        guard avPlayerInstance?.rate == 0 else {
            if !hasResumedFromBuffer {
                hasResumedFromBuffer = true
                avPlayerInstance?.currentItem?.preferredForwardBufferDuration = 5
            }
            return
        }

        let keepUp = avPlayerInstance?.currentItem?.isPlaybackLikelyToKeepUp ?? false
        let buffered = bufferedDuration()

        if keepUp || buffered > 0.3 {
            hasResumedFromBuffer = true
            let targetRate = _rate > 0 ? _rate : 1.0
            PLog.bufferResume(playerName, source: source, buffered: buffered, keepUp: keepUp)
            avPlayerInstance?.play()
            avPlayerInstance?.rate = targetRate
            avPlayerInstance?.currentItem?.preferredForwardBufferDuration = 5
        }
    }

    /**
     * 计算当前缓冲时长（秒）
     */
    private func bufferedDuration() -> TimeInterval {
        guard let item = avPlayerInstance?.currentItem else { return 0 }
        guard let range = item.loadedTimeRanges.first?.timeRangeValue else { return 0 }
        let currentTime = CMTimeGetSeconds(item.currentTime())
        let bufferedEnd = CMTimeGetSeconds(range.start) + CMTimeGetSeconds(range.duration)
        return max(0, bufferedEnd - currentTime)
    }

    /**
     * 移除缓冲观察者
     */
    private func removeBufferObservers() {
        keepUpObserver?.invalidate()
        keepUpObserver = nil
        bufferEmptyObserver?.invalidate()
        bufferEmptyObserver = nil
        loadedRangesObserver?.invalidate()
        loadedRangesObserver = nil
    }

    /**
     * 播放到结尾时的处理
     */
    @objc private func playerItemDidReachEnd(_ notification: Notification) {
        if isLooping {
            avPlayerInstance?.seek(to: .zero)
            avPlayerInstance?.play()
        } else {
            playbackState = .stopped
            context?.post(.playerPlaybackDidFinish, sender: self)
        }
    }

    // MARK: - Retry

    /**
     * 安排重试
     */
    private func scheduleRetry(url: URL, delay: TimeInterval) {
        cancelRetry()
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, let currentURL = self.currentURL, currentURL == url else { return }
                self.executeRetry(url: url)
            }
        }
    }

    /**
     * 执行重试
     */
    private func executeRetry(url: URL) {
        let prefetchService = context?.tryResolveService(PlayerPrefetchService.self)
        let finalURL = prefetchService?.proxyURL(for: url) ?? url
        let asset = AVURLAsset(url: finalURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: false])
        let retryItem = AVPlayerItem(asset: asset)
        retryItem.canUseNetworkResourcesForLiveStreamingWhilePaused = false
        replaceCurrentItem(with: retryItem)
        let targetRate = _rate > 0 ? _rate : 1.0
        avPlayerInstance?.play()
        avPlayerInstance?.rate = targetRate
    }

    /**
     * 取消重试
     */
    private func cancelRetry() {
        retryTimer?.invalidate()
        retryTimer = nil
        if let observer = networkObserver {
            NotificationCenter.default.removeObserver(observer)
            networkObserver = nil
        }
    }

    /**
     * 监听网络恢复以便重试
     */
    private func observeNetworkForRecovery() {
        cancelRetry()
        networkObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                guard self._playbackState == .failed, let url = self.currentURL else { return }
                self.stalledRetryCount = 0
                self.cancelRetry()
                self.executeRetry(url: url)
            }
        }
    }

    /**
     * 获取已加载时间范围的最大结束时间
     */
    private func loadedTimeRanges(of playerItem: AVPlayerItem) -> TimeInterval {
        var maxTime: TimeInterval = 0
        for timeRange in playerItem.loadedTimeRanges {
            let range = timeRange.timeRangeValue
            let end = CMTimeGetSeconds(range.end)
            if end > maxTime {
                maxTime = end
            }
        }
        return maxTime
    }
}

// MARK: - Time Observer Token

/**
 * 时间观察者令牌，用于移除观察
 */
public class TimeObserverToken {
    /**
     * 观察者唯一 key
     */
    let key: String
    /**
     * 关联的引擎插件
     */
    nonisolated(unsafe) weak var engine: PlayerEngineCorePlugin?

    /**
     * 初始化
     */
    init(key: String, engine: PlayerEngineCorePlugin) {
        self.key = key
        self.engine = engine
    }
}

// MARK: - CMTime Extension

/**
 * CMTime 扩展
 */
extension CMTime {
    /**
     * 是否为有效数值
     */
    var isNumeric: Bool {
        return !isIndefinite && timescale != 0
    }
}
