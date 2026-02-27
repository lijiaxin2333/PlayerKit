//
//  PlayerLoopingService.swift
//  playerkit
//
//  循环播放服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Types

/// 循环模式枚举
public enum PlayerLoopingMode {
    case none
    case loop
}

// MARK: - Looping Events

public extension Event {
    /// 循环状态改变
    static let playerLoopingDidChange: Event = "PlayerLoopingDidChange"
}

// MARK: - PlayerLoopingService Protocol

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
