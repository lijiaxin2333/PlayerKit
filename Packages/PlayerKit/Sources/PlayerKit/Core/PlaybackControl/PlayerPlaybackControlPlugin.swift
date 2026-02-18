//
//  PlayerPlaybackControlPlugin.swift
//  playerkit
//
//  播放控制组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 播放控制插件
 */
@MainActor
public final class PlayerPlaybackControlPlugin: BasePlugin, PlayerPlaybackControlService {

    public typealias ConfigModelType = PlayerPlaybackControlConfigModel

    // MARK: - Properties

    /**
     * 引擎服务依赖
     */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?
    @PlayerPlugin private var dataService: PlayerDataService?


    // MARK: - PlayerPlaybackControlService

    /**
     * 是否正在播放
     */
    public var isPlaying: Bool {
        return engineService?.playbackState == .playing
    }

    /**
     * 是否已暂停
     */
    public var isPaused: Bool {
        return engineService?.playbackState == .paused
    }

    /**
     * 是否可以播放
     */
    public var canPlay: Bool {
        guard let state = engineService?.playbackState else { return false }
        return state == .paused || state == .stopped || state == .seeking
    }

    /**
     * 是否可以暂停
     */
    public var canPause: Bool {
        return engineService?.playbackState == .playing
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    /**
     * 应用配置
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - Methods

    /**
     * 播放
     */
    public func play() {
        dataService?.updatePlayerInfo()
        engineService?.play()
    }

    /**
     * 暂停
     */
    public func pause() {
        engineService?.pause()
    }

    /**
     * 播放/暂停切换
     */
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /**
     * 停止
     */
    public func stop() {
        engineService?.stop()
    }

    /**
     * 重播（从头播放）
     */
    public func replay() {
        engineService?.seek(to: 0) { [weak self] finished in
            if finished {
                self?.play()
            }
        }
    }
}
