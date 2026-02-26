//
//  PlayerFullScreenService.swift
//  playerkit
//
//  全屏管理服务协议
//

import Foundation
import UIKit
import PlayerKit

// MARK: - FullScreen Types

/// 全屏状态枚举
public enum PlayerFullScreenState: Int {
    case normal = 0
    case fullScreen
    case transitioning
}

/// 全屏方向枚举
public enum PlayerFullScreenOrientation {
    case portrait
    case landscapeLeft
    case landscapeRight
    case auto
}

// MARK: - FullScreen Events

public extension Event {
    /// 全屏状态改变
    static let playerFullScreenStateChanged: Event = "PlayerFullScreenStateChanged"
    /// 将要进入全屏
    static let playerWillEnterFullScreen: Event = "PlayerWillEnterFullScreen"
    /// 已经进入全屏
    static let playerDidEnterFullScreen: Event = "PlayerDidEnterFullScreen"
    /// 将要退出全屏
    static let playerWillExitFullScreen: Event = "PlayerWillExitFullScreen"
    /// 已经退出全屏
    static let playerDidExitFullScreen: Event = "PlayerDidExitFullScreen"
}

// MARK: - FullScreen Service Protocol

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

// MARK: - FullScreen Config Model

/// 全屏配置模型
public class PlayerFullScreenConfigModel {

    /// 支持的全屏方向
    public var supportedOrientation: PlayerFullScreenOrientation = .auto

    public init() {}
}
