//
//  PlayerToastService.swift
//  playerkit
//
//  Toast 提示服务协议
//

import Foundation
import AVFoundation
import UIKit
import PlayerKit

/**
 * Toast 样式枚举
 */
public enum PlayerToastStyle {
    /** 信息 */
    case info
    /** 成功 */
    case success
    /** 警告 */
    case warning
    /** 错误 */
    case error
}

@MainActor
/**
 * Toast 提示服务协议，提供 Toast 消息和加载状态展示能力
 */
public protocol PlayerToastService: PluginService {

    /**
     * 显示 Toast 消息
     */
    func showToast(_ message: String, style: PlayerToastStyle, duration: TimeInterval)

    /**
     * 显示加载提示
     */
    func showLoading(_ message: String?)

    /**
     * 隐藏加载提示
     */
    func hideLoading()
}

/**
 * Toast 配置模型
 */
public class PlayerToastConfigModel {

    /** 默认显示时长（秒） */
    public var defaultDuration: TimeInterval = 2.0

    public init() {}
}
