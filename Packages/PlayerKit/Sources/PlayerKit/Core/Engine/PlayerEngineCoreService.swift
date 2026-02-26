//
//  PlayerEngineCoreService.swift
//  playerkit
//
//  Core 播放引擎服务协议（基于 AVPlayer）
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Types

/// 播放状态枚举
public enum PlayerPlaybackState: Int, Sendable {
    case stopped = 0
    case playing
    case paused
    case seeking
    case failed
}

/// 加载状态枚举
public enum PlayerLoadState: Int {
    case idle = 0
    case preparing
    case ready
    case loading
    case stalled
    case failed
}

/// 视频缩放模式枚举
public enum PlayerScalingMode: Int {
    case fit
    case fill
    case fillEdge
}

// MARK: - Engine Events

public extension Event {
    /// 播放器引擎已创建（粘性事件）
    static let playerEngineDidCreateSticky: Event = "PlayerEngineDidCreateSticky"
    /// 播放器引擎已改变
    static let playerEngineDidChange: Event = "PlayerEngineDidChange"
    /// 播放器引擎视图变化
    static let playerEngineViewDidChanged: Event = "PlayerEngineViewDidChanged"
    /// 播放器引擎创建渲染视图
    static let playerEngineDidCreateRenderView: Event = "PlayerEngineDidCreateRenderView"
    /// 获取到引擎模型
    static let playerDidFetchEngineModel: Event = "PlayerDidFetchEngineModel"
    /// 播放状态改变
    static let playerPlaybackStateChanged: Event = "PlayerPlaybackStateChanged"
    /// 准备好显示（粘性事件）
    static let playerReadyForDisplaySticky: Event = "PlayerReadyForDisplaySticky"
    /// 准备播放
    static let playerReadyToPlay: Event = "PlayerReadyToPlay"
    /// 准备播放（粘性事件）
    static let playerReadyToPlaySticky: Event = "PlayerReadyToPlaySticky"
    /// 加载状态改变
    static let playerLoadStateDidChange: Event = "PlayerLoadStateDidChange"
    /// 播放完成
    static let playerPlaybackDidFinish: Event = "PlayerPlaybackDidFinish"
    /// 播放失败
    static let playerPlaybackDidFail: Event = "PlayerPlaybackDidFail"
    /// 开始卡顿
    static let playerPlayingStalledBegin: Event = "PlayerPlayingStalledBegin"
    /// 结束卡顿
    static let playerPlayingStalledEnd: Event = "PlayerPlayingStalledEnd"
    /// 缩放模式改变
    static let playerScaleModeChanged: Event = "PlayerScaleModeChanged"
    /// 起播前开始加载缓存
    static let playerStartPlayLoadBufferBegin: Event = "PlayerStartPlayLoadBufferBegin"
    /// 起播前结束加载缓存
    static let playerStartPlayLoadBufferEnd: Event = "PlayerStartPlayLoadBufferEnd"
}

// MARK: - PlayerEngineCoreService Protocol

/**
 * 播放引擎核心服务协议（基于 AVPlayer）
 */
@MainActor
public protocol PlayerEngineCoreService: PluginService {

    // MARK: - 播放器实例

    /**
     * 底层 AVPlayer
     */
    var avPlayer: AVPlayer? { get }

    /**
     * 播放器渲染视图
     */
    var playerView: UIView? { get }

    /**
     * 当前播放的 URL
     */
    var currentURL: URL? { get }

    // MARK: - 状态

    /**
     * 播放状态
     */
    var playbackState: PlayerPlaybackState { get }

    /**
     * 加载状态
     */
    var loadState: PlayerLoadState { get }

    /**
     * 当前播放时间（秒）
     */
    var currentTime: TimeInterval { get }

    /**
     * 总时长（秒）
     */
    var duration: TimeInterval { get }

    /**
     * 缓冲进度（0-1）
     */
    var bufferProgress: Double { get }

    /**
     * 首帧是否已渲染到屏幕
     */
    var isReadyForDisplay: Bool { get }

    // MARK: - 播放控制

    /**
     * 播放速率（倍速）
     */
    var rate: Float { get set }

    /**
     * 是否循环播放
     */
    var isLooping: Bool { get set }

    /**
     * 音量（0-1）
     */
    var volume: Float { get set }

    /**
     * 视频缩放模式
     */
    var scalingMode: PlayerScalingMode { get set }

    // MARK: - 方法

    /**
     * 设置播放 URL
     */
    func setURL(_ url: URL)

    /**
     * 准备播放
     */
    func prepareToPlay()

    /**
     * 播放
     */
    func play()

    /**
     * 暂停
     */
    func pause()

    /**
     * 停止
     */
    func stop()

    /**
     * Seek 到指定时间
     */
    func seek(to time: TimeInterval)

    /**
     * Seek 到指定时间，完成后回调
     */
    func seek(to time: TimeInterval, completion: (@Sendable (Bool) -> Void)?)

    /**
     * 添加时间观察者
     */
    func addPeriodicTimeObserver(interval: TimeInterval, queue: DispatchQueue, block: @Sendable @escaping (TimeInterval) -> Void) -> AnyObject?

    /**
     * 移除时间观察者
     */
    func removeTimeObserver(_ observer: AnyObject?)

    /**
     * 替换当前播放项
     */
    func replaceCurrentItem(with item: AVPlayerItem?)

    /**
     * 重置播放器
     */
    func reset()

    // MARK: - Reuse

    /**
     * 是否可复用
     */
    var canReuse: Bool { get }

    /**
     * 是否正在回收
     */
    var isRecycling: Bool { get }

    /**
     * 准备复用
     */
    func prepareForReuse()

    /**
     * 从回收池出队
     */
    func didDequeueForReuse()

    /**
     * 分离核心资源（AVPlayer + RenderView）
     * 用于引擎池只缓存 AVPlayer + RenderView 这一对
     * 调用后 Plugin 将处于空状态
     */
    func detachCore() -> (avPlayer: AVPlayer, renderView: PlayerEngineRenderView)?

    /**
     * 接管已准备好的核心资源
     * 用于引擎池出队时让新 Plugin 接管缓存的 AVPlayer + RenderView
     */
    func adoptCore(player: AVPlayer, renderView: PlayerEngineRenderView)
}

// MARK: - 配置模型

/**
 * 播放引擎配置模型
 */
public class PlayerEngineCoreConfigModel {

    /**
     * 是否自动播放
     */
    public var autoPlay: Bool = false

    /**
     * 是否循环播放
     */
    public var isLooping: Bool = false

    /**
     * 初始音量
     */
    public var initialVolume: Float = 1.0

    /**
     * 初始播放速率
     */
    public var initialRate: Float = 1.0

    /**
     * 缓冲策略
     */
    public var preferredBufferDuration: TimeInterval = 30.0

    /**
     * 缩放模式
     */
    public var scalingMode: PlayerScalingMode = .fill

    /**
     * 初始化
     */
    public init() {}
}
