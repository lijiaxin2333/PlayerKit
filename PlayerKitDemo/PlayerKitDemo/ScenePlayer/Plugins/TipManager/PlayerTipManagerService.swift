//
//  PlayerTipManagerService.swift
//  playerkit
//
//  提示管理服务协议
//

import Foundation
import AVFoundation
import UIKit
import PlayerKit

// MARK: - 提示类型

public enum PlayerTipType {
    case buffering      // 缓冲中
    case loading        // 加载中
    case error          // 错误
    case warning        // 警告
    case info           // 信息
}

// MARK: - 提示管理服务

@MainActor
public protocol PlayerTipManagerService: PluginService {

    /// 显示提示
    func showTip(_ type: PlayerTipType, message: String)

    /// 隐藏提示
    func hideTip(_ type: PlayerTipType)

    /// 隐藏所有提示
    func hideAllTips()
}

// MARK: - 配置模型

public class PlayerTipManagerConfigModel {

    /// 提示显示时长
    public var displayDuration: TimeInterval = 2.0

    public init() {}
}
