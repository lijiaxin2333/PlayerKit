//
//  PlayerEngineCoreService.swift
//  playerkit
//
//  Core 播放引擎服务协议（基于 AVPlayer）
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 播放状态

public enum PlayerPlaybackState: Int {
    case stopped = 0
    case playing
    case paused
    case seeking
    case failed
}

// MARK: - 加载状态

public enum PlayerLoadState: Int {
    case idle = 0
    case preparing
    case ready
    case loading
    case stalled
    case failed
}

// MARK: - 视频缩放模式

public enum PlayerScalingMode: Int {
    case fit            // 适应屏幕，留黑边
    case fill           // 填充屏幕，可能裁剪
    case fillEdge       // 等比例填充，不裁剪
}

// MARK: - 播放引擎核心服务

@MainActor
public protocol PlayerEngineCoreService: PluginService {

    // MARK: - 播放器实例

    /// 底层 AVPlayer
    var avPlayer: AVPlayer? { get }

    /// 播放器渲染视图
    var playerView: UIView? { get }

    /// 当前播放的 URL
    var currentURL: URL? { get }

    // MARK: - 状态

    /// 播放状态
    var playbackState: PlayerPlaybackState { get }

    /// 加载状态
    var loadState: PlayerLoadState { get }

    /// 当前播放时间（秒）
    var currentTime: TimeInterval { get }

    /// 总时长（秒）
    var duration: TimeInterval { get }

    /// 缓冲进度（0-1）
    var bufferProgress: Double { get }

    /// 首帧是否已渲染到屏幕
    var isReadyForDisplay: Bool { get }

    // MARK: - 播放控制

    /// 播放速率（倍速）
    var rate: Float { get set }

    /// 是否循环播放
    var isLooping: Bool { get set }

    /// 音量（0-1）
    var volume: Float { get set }

    /// 视频缩放模式
    var scalingMode: PlayerScalingMode { get set }

    // MARK: - 方法

    /// 设置播放 URL
    func setURL(_ url: URL)

    /// 准备播放
    func prepareToPlay()

    /// 播放
    func play()

    /// 暂停
    func pause()

    /// 停止
    func stop()

    /// Seek 到指定时间
    func seek(to time: TimeInterval)

    /// Seek 到指定时间，完成后回调
    func seek(to time: TimeInterval, completion: ((Bool) -> Void)?)

    /// 添加时间观察者
    func addPeriodicTimeObserver(interval: TimeInterval, queue: DispatchQueue, block: @escaping (TimeInterval) -> Void) -> AnyObject?

    /// 移除时间观察者
    func removeTimeObserver(_ observer: AnyObject?)

    /// 替换当前播放项
    func replaceCurrentItem(with item: AVPlayerItem?)

    /// 重置播放器
    func reset()

    // MARK: - Reuse

    var canReuse: Bool { get }

    var isRecycling: Bool { get }

    func prepareForReuse()

    func didDequeueForReuse()
}

// MARK: - 配置模型

public class PlayerEngineCoreConfigModel {

    /// 是否自动播放
    public var autoPlay: Bool = false

    /// 是否循环播放
    public var isLooping: Bool = false

    /// 初始音量
    public var initialVolume: Float = 1.0

    /// 初始播放速率
    public var initialRate: Float = 1.0

    /// 缓冲策略
    public var preferredBufferDuration: TimeInterval = 30.0

    /// 缩放模式
    public var scalingMode: PlayerScalingMode = .fill

    public init() {}
}
