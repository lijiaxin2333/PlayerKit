//
//  PlayerController.swift
//  playerkit
//

import Foundation
import UIKit

/** 视频播放控制器，封装播放器操作的高层接口 */
@MainActor
public final class PlayerController {

    // MARK: - Properties

    /** 内部持有的播放器实例 */
    private let player: Player

    /** 当前是否正在播放 */
    public private(set) var isPlaying: Bool = false
    /** 当前播放时间（秒） */
    public private(set) var currentTime: TimeInterval = 0
    /** 视频总时长（秒） */
    public private(set) var duration: TimeInterval = 0

    // MARK: - 手动注入的服务

    /** 引擎服务，提供底层播放控制 */
    public var engineService: PlayerEngineCoreService? {
        return player.context.resolveService(PlayerEngineCoreService.self)
    }

    /** 数据服务，管理视频数据模型 */
    public var dataService: PlayerDataService? {
        return player.context.resolveService(PlayerDataService.self)
    }

    /** 流程服务，管理播放流程状态 */
    public var processService: PlayerProcessService? {
        return player.context.resolveService(PlayerProcessService.self)
    }

    /** 埋点服务，发送播放器事件追踪 */
    public var trackerService: PlayerTrackerService? {
        return player.context.resolveService(PlayerTrackerService.self)
    }

    /** 倍速服务，管理播放倍速 */
    public var speedService: PlayerSpeedService? {
        return player.context.resolveService(PlayerSpeedService.self)
    }

    // MARK: - Initialization

    /** 初始化播放控制器 */
    public init(player: Player) {
        self.player = player
    }

    // MARK: - Playback Control

    /** 设置视频 URL 并通知相关服务 */
    public func setVideoURL(_ url: URL) {
        dataService?.setVideoURL(url)
        engineService?.setURL(url)
        trackerService?.sendEvent("url_set", params: [:])
    }

    /** 开始播放 */
    public func play() {
        engineService?.play()
        print("[PlayerController] 播放")
    }

    /** 暂停播放 */
    public func pause() {
        engineService?.pause()
        print("[PlayerController] 暂停")
    }

    /** 停止播放 */
    public func stop() {
        engineService?.stop()
        print("[PlayerController] 停止")
    }

    /** 跳转到指定时间位置 */
    public func seek(to time: TimeInterval) {
        engineService?.seek(to: time)
    }

    /** 设置播放倍速并上报 */
    public func setSpeed(_ speed: Float) {
        speedService?.setSpeed(speed)
        trackerService?.sendEvent("speed_change", params: [:])
    }

    // MARK: - State Query

    /** 获取当前播放器视图 */
    public var playerView: UIView? {
        return engineService?.playerView
    }

    /** 获取当前播放状态描述 */
    public var stateDescription: String {
        return engineService?.playbackState.description ?? "unknown"
    }

    /** 获取播放进度（0-1） */
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
}

// MARK: - PlayerPlaybackState 扩展

extension PlayerPlaybackState {
    /** 播放状态的中文描述 */
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
