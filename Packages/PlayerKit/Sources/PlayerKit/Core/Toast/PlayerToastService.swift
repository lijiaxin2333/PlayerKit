//
//  PlayerToastService.swift
//  playerkit
//
//  Toast 提示服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Toast 样式

public enum PlayerToastStyle {
    case info
    case success
    case warning
    case error
}

// MARK: - Toast 服务

@MainActor
public protocol PlayerToastService: CCLCompService {

    /// 显示 Toast
    func showToast(_ message: String, style: PlayerToastStyle, duration: TimeInterval)

    /// 显示加载提示
    func showLoading(_ message: String?)

    /// 隐藏加载提示
    func hideLoading()
}

// MARK: - 配置模型

public class PlayerToastConfigModel {

    /// 默认显示时长
    public var defaultDuration: TimeInterval = 2.0

    public init() {}
}
