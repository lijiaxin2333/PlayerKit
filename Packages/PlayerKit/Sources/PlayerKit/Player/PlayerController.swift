//
//  PlayerController.swift
//  playerkit
//
//  视频播放控制器 - 手动服务注入（简化版）
//

import Foundation
import UIKit

// MARK: - 视频播放控制器

/// 视频播放控制器 - 管理视频播放
@MainActor
public final class PlayerController {

    // MARK: - Properties

    private let player: Player

    public private(set) var isPlaying: Bool = false
    public private(set) var currentTime: TimeInterval = 0
    public private(set) var duration: TimeInterval = 0

    // MARK: - 手动注入的服务

    public var engineService: PlayerEngineCoreService? {
        return player.context.resolveService(PlayerEngineCoreService.self)
    }

    public var dataService: PlayerDataService? {
        return player.context.resolveService(PlayerDataService.self)
    }

    public var processService: PlayerProcessService? {
        return player.context.resolveService(PlayerProcessService.self)
    }

    public var trackerService: PlayerTrackerService? {
        return player.context.resolveService(PlayerTrackerService.self)
    }

    public var speedService: PlayerSpeedService? {
        return player.context.resolveService(PlayerSpeedService.self)
    }

    // MARK: - Initialization

    public init(player: Player) {
        self.player = player
    }

    // MARK: - Playback Control

    /// 设置视频 URL
    public func setVideoURL(_ url: URL) {
        dataService?.setVideoURL(url)
        engineService?.setURL(url)
        trackerService?.sendEvent("url_set", params: [:])
    }

    /// 播放
    public func play() {
        engineService?.play()
        print("[PlayerController] 播放")
    }

    /// 暂停
    public func pause() {
        engineService?.pause()
        print("[PlayerController] 暂停")
    }

    /// 停止
    public func stop() {
        engineService?.stop()
        print("[PlayerController] 停止")
    }

    /// Seek 到指定时间
    public func seek(to time: TimeInterval) {
        engineService?.seek(to: time)
    }

    /// 设置倍速
    public func setSpeed(_ speed: Float) {
        speedService?.setSpeed(speed)
        trackerService?.sendEvent("speed_change", params: [:])
    }

    // MARK: - State Query

    /// 获取当前播放器视图
    public var playerView: UIView? {
        return engineService?.playerView
    }

    /// 获取当前状态描述
    public var stateDescription: String {
        return engineService?.playbackState.description ?? "unknown"
    }

    /// 获取播放进度 (0-1)
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}

// MARK: - PlayerPlaybackState 扩展

extension PlayerPlaybackState {
    var description: String {
        switch self {
        case .stopped: return "停止"
        case .playing: return "播放中"
        case .paused: return "暂停"
        case .seeking: return "寻址中"
        case .failed: return "失败"
        }
    }
}
