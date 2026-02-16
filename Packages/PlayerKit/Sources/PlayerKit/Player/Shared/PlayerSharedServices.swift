//
//  PlayerSharedServices.swift
//  playerkit
//

import Foundation
import UIKit

/** 播放器类型标识 */
public struct PlayerType: Hashable, Sendable {
    /** 类型原始值 */
    public let rawValue: String

    /** 初始化播放器类型 */
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /** 短视频播放器 */
    public static let shortVideo = PlayerType(rawValue: "short")

    /** 长视频播放器 */
    public static let longVideo = PlayerType(rawValue: "long")

    /** 直播播放器 */
    public static let live = PlayerType(rawValue: "live")
}

/** 当前播放器共享服务协议，管理全局的当前播放器实例 */
@MainActor
public protocol PlayerSharedCurrentPlayerService: PluginService {

    /** 当前播放器实例 */
    var currentPlayer: ContextHolder? { get }

    /** 当前播放器类型 */
    var currentPlayerType: PlayerType? { get }

    /** 设置当前播放器及其类型 */
    func setCurrentPlayer(_ player: ContextHolder?, type: PlayerType?)

    /** 清除当前播放器 */
    func clearCurrentPlayer()
}

/** 全屏共享服务协议，管理全局全屏状态 */
@MainActor
public protocol PlayerSharedFullScreenService: PluginService {

    /** 是否处于全屏模式 */
    var isFullScreen: Bool { get }

    /** 全屏容器视图 */
    var fullScreenContainer: UIView? { get }

    /** 进入全屏模式 */
    func enterFullScreen(with container: UIView?)

    /** 退出全屏模式 */
    func exitFullScreen()

    /** 切换全屏状态 */
    func toggleFullScreen()
}

/** 倍速共享服务协议（简化版），管理全局倍速设置 */
@MainActor
public protocol PlayerSharedSpeedServiceSimple: PluginService {

    /** 当前倍速 */
    var currentSpeed: Float { get }

    /** 可用倍速列表 */
    var availableSpeeds: [Float] { get }

    /** 设置倍速 */
    func setSpeed(_ speed: Float)

    /** 添加倍速变化监听器 */
    @discardableResult
    func addSpeedChangeListener(_ handler: @escaping (Float) -> Void) -> AnyObject?
}

/** 循环播放共享服务协议，管理全局循环播放设置 */
@MainActor
public protocol PlayerSharedLoopingService: PluginService {

    /** 是否循环播放 */
    var isLooping: Bool { get }

    /** 设置循环播放开关 */
    func setLooping(_ enabled: Bool)

    /** 切换循环播放状态 */
    func toggleLooping()
}

/** 定时关闭共享服务协议，管理定时自动停止播放 */
@MainActor
public protocol PlayerSharedTimedOffService: PluginService {

    /** 定时关闭时间间隔（秒） */
    var timedOffInterval: TimeInterval? { get }

    /** 剩余时间（秒） */
    var remainingTime: TimeInterval? { get }

    /** 是否已启用定时关闭 */
    var isTimedOffEnabled: Bool { get }

    /** 设置定时关闭间隔，0 表示取消 */
    func setTimedOff(interval: TimeInterval)

    /** 取消定时关闭 */
    func cancelTimedOff()
}
