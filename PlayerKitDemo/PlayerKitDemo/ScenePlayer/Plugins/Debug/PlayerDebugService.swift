//
//  PlayerDebugService.swift
//  playerkit
//
//  调试服务协议
//

import Foundation

import UIKit
import BizPlayerKit

/**
 * 调试服务协议
 */
@MainActor
public protocol PlayerDebugService: PluginService {

    /**
     * 是否启用调试模式
     */
    var isDebugEnabled: Bool { get set }

    /**
     * 记录调试日志
     */
    func log(_ message: String, level: PlayerLogLevel)

    /**
     * 显示调试面板
     */
    func showDebugPanel()

    /**
     * 隐藏调试面板
     */
    func hideDebugPanel()
}

/**
 * 日志级别枚举
 */
public enum PlayerLogLevel: Int {
    case verbose = 0
    case debug
    case info
    case warning
    case error
}

/**
 * 调试配置模型
 */
public class PlayerDebugConfigModel {

    /**
     * 是否启用调试模式
     */
    public var enabled: Bool = false

    /**
     * 日志级别
     */
    public var logLevel: PlayerLogLevel = .info

    /**
     * 是否显示调试面板
     */
    public var showDebugPanel: Bool = false

    /**
     * 初始化配置
     */
    public init() {}
}
