//
//  PlayerProcessService.swift
//  playerkit
//
//  播放进度管理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 进度状态

public enum PlayerProgressState {
    case idle       // 空闲
    case scrubbing  // 拖动中
    case seeking    // Seek 中
}

// MARK: - 进度管理服务

@MainActor
public protocol PlayerProcessService: PluginService {

    /// 当前进度（0-1）
    var progress: Double { get }

    /// 当前播放时间（秒）
    var currentTime: TimeInterval { get }

    /// 总时长（秒）
    var duration: TimeInterval { get }

    /// 缓冲进度（0-1）
    var bufferProgress: Double { get }

    /// 进度状态
    var progressState: PlayerProgressState { get }

    /// 是否正在拖动
    var isScrubbing: Bool { get }

    /// 观察进度变化
    func observeProgress(_ handler: @escaping (Double, TimeInterval) -> Void)

    /// 移除观察者
    func removeProgressObserver(_ observer: AnyObject?)

    /// 开始拖动
    func beginScrubbing()

    /// 拖动中
    func scrubbing(to progress: Double)

    /// 结束拖动
    func endScrubbing()

    /// Seek 到指定进度
    func seek(to progress: Double, completion: ((Bool) -> Void)?)
}

// MARK: - 配置模型

public class PlayerProcessConfigModel {

    /// 进度更新间隔（秒）
    public var updateInterval: TimeInterval = 0.1

    /// 是否显示缓冲进度
    public var showBufferProgress: Bool = true

    /// 进度拖动灵敏度
    public var scrubbingSensitivity: Double = 0.01

    public init() {}
}
