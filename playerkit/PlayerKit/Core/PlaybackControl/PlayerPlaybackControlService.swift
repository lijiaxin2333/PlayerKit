//
//  PlayerPlaybackControlService.swift
//  playerkit
//
//  播放控制服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 播放控制服务

@MainActor
public protocol PlayerPlaybackControlService: CCLCompService {

    /// 是否正在播放
    var isPlaying: Bool { get }

    /// 是否暂停
    var isPaused: Bool { get }

    /// 是否可以播放
    var canPlay: Bool { get }

    /// 是否可以暂停
    var canPause: Bool { get }

    /// 播放
    func play()

    /// 暂停
    func pause()

    /// 播放/暂停切换
    func togglePlayPause()

    /// 停止
    func stop()

    /// 重播
    func replay()
}

// MARK: - 配置模型

public class PlayerPlaybackControlConfigModel {

    /// 是否自动播放
    public var autoPlay: Bool = false

    /// 播放结束时是否自动重播
    public var autoReplay: Bool = false

    public init() {}
}
