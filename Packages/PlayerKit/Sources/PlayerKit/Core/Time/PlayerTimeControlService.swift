//
//  PlayerTimeControlService.swift
//  playerkit
//
//  时间控制服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 时间格式化样式

/**
 * 时间格式化样式枚举
 */
public enum PlayerTimeStyle {
    /**
     * 标准格式，00:00
     */
    case standard
    /**
     * 完整格式，00:00:00
     */
    case full
    /**
     * 简短格式，0:00
     */
    case short
    /**
     * verbose 格式，如 1分30秒
     */
    case verbose
}

// MARK: - 时间控制服务

/**
 * 时间控制服务协议
 */
@MainActor
public protocol PlayerTimeControlService: PluginService {

    /**
     * 当前播放时间（秒）
     */
    var currentTime: TimeInterval { get }

    /**
     * 总时长（秒）
     */
    var duration: TimeInterval { get }

    /**
     * 剩余时长（秒）
     */
    var remainingTime: TimeInterval { get }

    /**
     * 已观看时长（秒）
     */
    var watchedDuration: TimeInterval { get }

    /**
     * 格式化时间
     */
    func formatTime(_ time: TimeInterval, style: PlayerTimeStyle) -> String

    /**
     * 当前时间字符串
     */
    func currentTimeString(style: PlayerTimeStyle) -> String

    /**
     * 总时长字符串
     */
    func durationString(style: PlayerTimeStyle) -> String

    /**
     * 剩余时间字符串
     */
    func remainingTimeString(style: PlayerTimeStyle) -> String

    /**
     * 时间进度描述（如: 01:30 / 03:45）
     */
    func timeProgressString(style: PlayerTimeStyle) -> String
}

// MARK: - 配置模型

/**
 * 时间控制配置模型
 */
public class PlayerTimeControlConfigModel {

    /**
     * 默认时间格式
     */
    public var defaultStyle: PlayerTimeStyle = .standard

    /**
     * 初始化
     */
    public init() {}
}
