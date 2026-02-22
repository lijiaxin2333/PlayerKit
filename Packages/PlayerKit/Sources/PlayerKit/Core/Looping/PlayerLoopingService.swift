//
//  PlayerLoopingService.swift
//  playerkit
//
//  循环播放服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 循环模式

/**
 * 循环模式枚举
 * - 播放器只感知当前视频的循环，列表循环由列表层负责
 */
public enum PlayerLoopingMode {
    /**
     * 不循环
     */
    case none
    /**
     * 单视频循环
     */
    case loop
}

// MARK: - 循环播放服务

/**
 * 循环播放服务协议
 */
@MainActor
public protocol PlayerLoopingService: PluginService {

    /**
     * 循环模式
     */
    var loopingMode: PlayerLoopingMode { get set }

    /**
     * 是否循环
     */
    var isLooping: Bool { get }

    /**
     * 切换循环模式
     */
    func toggleLooping()

    /**
     * 设置循环模式
     */
    func setLoopingMode(_ mode: PlayerLoopingMode)
}

// MARK: - 配置模型

/**
 * 循环播放配置模型
 */
public class PlayerLoopingConfigModel {

    /**
     * 默认循环模式
     */
    public var defaultMode: PlayerLoopingMode = .none

    /**
     * 初始化
     */
    public init() {}
}
