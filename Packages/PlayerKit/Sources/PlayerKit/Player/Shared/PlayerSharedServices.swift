//
//  PlayerSharedServices.swift
//  playerkit
//
//  Shared 层服务协议
//

import Foundation
import UIKit

// MARK: - 播放器类型标识

/// 播放器类型标识
public struct PlayerType: Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// 短视频播放器
    public static let shortVideo = PlayerType(rawValue: "short")

    /// 长视频播放器
    public static let longVideo = PlayerType(rawValue: "long")

    /// 直播播放器
    public static let live = PlayerType(rawValue: "live")
}

// MARK: - 当前播放器服务

/// 当前播放器共享服务协议 - 管理全局的当前播放器实例
@MainActor
public protocol PlayerSharedCurrentPlayerService: CCLCompService {

    /// 当前播放器
    var currentPlayer: CCLContextHolder? { get }

    /// 当前播放器类型
    var currentPlayerType: PlayerType? { get }

    /// 设置当前播放器
    /// - Parameters:
    ///   - player: 播放器实例
    ///   - type: 播放器类型
    func setCurrentPlayer(_ player: CCLContextHolder?, type: PlayerType?)

    /// 清除当前播放器
    func clearCurrentPlayer()
}

// MARK: - 全屏服务

/// 全屏共享服务协议 - 管理全局全屏状态
@MainActor
public protocol PlayerSharedFullScreenService: CCLCompService {

    /// 是否全屏
    var isFullScreen: Bool { get }

    /// 全屏容器视图
    var fullScreenContainer: UIView? { get }

    /// 进入全屏
    /// - Parameter container: 全屏容器视图
    func enterFullScreen(with container: UIView?)

    /// 退出全屏
    func exitFullScreen()

    /// 切换全屏状态
    func toggleFullScreen()
}

// MARK: - 倍速服务

/// 倍速共享服务协议（简化版）- 管理全局倍速设置
/// 注意：完整版在 PlayerSpeedService.swift 中定义为 PlayerSharedSpeedService
@MainActor
public protocol PlayerSharedSpeedServiceSimple: CCLCompService {

    /// 当前倍速
    var currentSpeed: Float { get }

    /// 可用倍速列表
    var availableSpeeds: [Float] { get }

    /// 设置倍速
    /// - Parameter speed: 倍速值
    func setSpeed(_ speed: Float)

    /// 添加倍速变化监听
    /// - Parameter handler: 变化回调
    /// - Returns: 监听 token
    @discardableResult
    func addSpeedChangeListener(_ handler: @escaping (Float) -> Void) -> AnyObject?
}

// MARK: - 循环播放服务

/// 循环播放共享服务协议 - 管理全局循环播放设置
@MainActor
public protocol PlayerSharedLoopingService: CCLCompService {

    /// 是否循环播放
    var isLooping: Bool { get }

    /// 设置循环播放
    /// - Parameter enabled: 是否启用
    func setLooping(_ enabled: Bool)

    /// 切换循环播放状态
    func toggleLooping()
}

// MARK: - 定时关闭服务

/// 定时关闭共享服务协议 - 管理定时关闭功能
@MainActor
public protocol PlayerSharedTimedOffService: CCLCompService {

    /// 定时关闭时间（秒）
    var timedOffInterval: TimeInterval? { get }

    /// 剩余时间（秒）
    var remainingTime: TimeInterval? { get }

    /// 是否启用定时关闭
    var isTimedOffEnabled: Bool { get }

    /// 设置定时关闭
    /// - Parameter interval: 关闭时间（秒），0 表示取消
    func setTimedOff(interval: TimeInterval)

    /// 取消定时关闭
    func cancelTimedOff()
}
