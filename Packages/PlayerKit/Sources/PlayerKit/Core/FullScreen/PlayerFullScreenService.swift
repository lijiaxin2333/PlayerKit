//
//  PlayerFullScreenService.swift
//  playerkit
//
//  全屏管理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 全屏状态

public enum PlayerFullScreenState: Int {
    case normal = 0
    case fullScreen
    case transitioning
}

// MARK: - 全屏方向

public enum PlayerFullScreenOrientation {
    case portrait       // 竖屏
    case landscapeLeft  // 横屏左
    case landscapeRight // 横屏右
    case auto           // 自动
}

// MARK: - 全屏服务

@MainActor
public protocol PlayerFullScreenService: PluginService {

    /// 当前全屏状态
    var fullScreenState: PlayerFullScreenState { get }

    /// 是否全屏
    var isFullScreen: Bool { get }

    /// 支持的全屏方向
    var supportedOrientation: PlayerFullScreenOrientation { get set }

    /// 进入全屏
    func enterFullScreen(orientation: PlayerFullScreenOrientation, animated: Bool)

    /// 退出全屏
    func exitFullScreen(animated: Bool)

    /// 切换全屏
    func toggleFullScreen(orientation: PlayerFullScreenOrientation, animated: Bool)
}

// MARK: - 配置模型

public class PlayerFullScreenConfigModel {

    /// 支持的全屏方向
    public var supportedOrientation: PlayerFullScreenOrientation = .auto

    /// 进入全屏是否动画
    public var animated: Bool = true

    /// 是否自动旋转
    public var autoRotate: Bool = true

    public init() {}
}
