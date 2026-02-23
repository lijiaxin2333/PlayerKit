//
//  PlayerProcessService.swift
//  playerkit
//
//  播放进度管理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Types

public enum PlayerProgressState {
    case idle
    case scrubbing
    case seeking
}

// MARK: - Process Events

public extension Event {
    /// 进度开始拖动
    static let playerProgressBeginScrubbing: Event = "PlayerProgressBeginScrubbing"
    /// 进度拖动中
    static let playerProgressScrubbing: Event = "PlayerProgressScrubbing"
    /// 进度结束拖动
    static let playerProgressEndScrubbing: Event = "PlayerProgressEndScrubbing"
    /// Slider 触发的 Seek 开始
    static let playerSliderSeekBegin: Event = "PlayerSliderSeekBegin"
    /// Slider 触发的 Seek 结束
    static let playerSliderSeekEnd: Event = "PlayerSliderSeekEnd"
    /// 手势触发的 Seek 开始
    static let playerGestureSeekBegin: Event = "PlayerGestureSeekBegin"
    /// 手势触发的 Seek 结束
    static let playerGestureSeekEnd: Event = "PlayerGestureSeekEnd"
    /// Seek 开始
    static let playerSeekBegin: Event = "PlayerSeekBegin"
    /// Seek 结束
    static let playerSeekEnd: Event = "PlayerSeekEnd"
}

// MARK: - PlayerProcessService Protocol

@MainActor
public protocol PlayerProcessService: PluginService {

    /**
     * 当前进度（0-1）
     */
    var progress: Double { get }

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
     * 进度状态
     */
    var progressState: PlayerProgressState { get }

    /**
     * 是否正在拖动
     */
    var isScrubbing: Bool { get }

    /**
     * 观察进度变化
     * - Parameter handler: 进度回调，参数为 (progress, currentTime)
     * - Returns: 观察者 token，用于移除监听
     */
    @discardableResult
    func observeProgress(_ handler: @escaping (Double, TimeInterval) -> Void) -> String

    /**
     * 移除指定观察者
     * - Parameter token: observeProgress 返回的 token
     */
    func removeProgressObserver(token: String)

    /**
     * 移除所有观察者
     */
    func removeAllProgressObservers()

    /**
     * 开始拖动
     */
    func beginScrubbing()

    /**
     * 拖动中
     */
    func scrubbing(to progress: Double)

    /**
     * 结束拖动
     */
    func endScrubbing()

    /**
     * Seek 到指定进度
     */
    func seek(to progress: Double, completion: (@Sendable (Bool) -> Void)?)
}

// MARK: - 配置模型

public class PlayerProcessConfigModel {

    /**
     * 进度更新间隔（秒）
     */
    public var updateInterval: TimeInterval = 0.1

    /**
     * 是否显示缓冲进度
     */
    public var showBufferProgress: Bool = true

    /**
     * 进度拖动灵敏度
     */
    public var scrubbingSensitivity: Double = 0.01

    public init() {}
}
