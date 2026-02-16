//
//  PlayerSharedComps.swift
//  playerkit
//

import Foundation
import UIKit

/** 当前播放器共享插件，管理全局的当前播放器实例 */
@MainActor
public final class PlayerSharedCurrentPlayerPlugin: SharedBasePlugin, PlayerSharedCurrentPlayerService {

    /** 配置模型类型 */
    public typealias ConfigModelType = EmptyConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerSharedCurrentPlayerService"

    /** 当前播放器实例 */
    private var _currentPlayer: ContextHolder?
    /** 当前播放器类型 */
    private var _currentPlayerType: PlayerType?

    /** 获取当前播放器 */
    public var currentPlayer: ContextHolder? {
        return _currentPlayer
    }

    /** 获取当前播放器类型 */
    public var currentPlayerType: PlayerType? {
        return _currentPlayerType
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
        print("[PlayerSharedCurrentPlayerPlugin] 共享组件已创建")
    }

    /** 设置当前播放器及其类型 */
    public func setCurrentPlayer(_ player: ContextHolder?, type: PlayerType?) {
        _currentPlayer = player
        _currentPlayerType = type
        print("[PlayerSharedCurrentPlayerPlugin] 设置当前播放器: \(type?.rawValue ?? "unknown")")
    }

    /** 清除当前播放器 */
    public func clearCurrentPlayer() {
        _currentPlayer = nil
        _currentPlayerType = nil
        print("[PlayerSharedCurrentPlayerPlugin] 清除当前播放器")
    }
}

/** 全屏共享插件，管理全局全屏状态 */
@MainActor
public final class PlayerSharedFullScreenPlugin: SharedBasePlugin, PlayerSharedFullScreenService {

    /** 配置模型类型 */
    public typealias ConfigModelType = EmptyConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerSharedFullScreenService"

    /** 是否处于全屏状态 */
    private var _isFullScreen: Bool = false
    /** 全屏容器视图 */
    private var _fullScreenContainer: UIView?
    /** 倍速变化回调映射 */
    private var speedChangeHandlers: [ObjectIdentifier: (Float) -> Void] = [:]
    /** 回调 token 计数器 */
    private var handlerToken: Int = 0

    /** 是否处于全屏 */
    public var isFullScreen: Bool {
        return _isFullScreen
    }

    /** 全屏容器视图 */
    public var fullScreenContainer: UIView? {
        return _fullScreenContainer
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
        print("[PlayerSharedFullScreenPlugin] 共享组件已创建")
    }

    /** 进入全屏模式 */
    public func enterFullScreen(with container: UIView?) {
        _isFullScreen = true
        _fullScreenContainer = container
        print("[PlayerSharedFullScreenPlugin] 进入全屏")
    }

    /** 退出全屏模式 */
    public func exitFullScreen() {
        _isFullScreen = false
        _fullScreenContainer = nil
        print("[PlayerSharedFullScreenPlugin] 退出全屏")
    }

    /** 切换全屏状态 */
    public func toggleFullScreen() {
        if _isFullScreen {
            exitFullScreen()
        } else {
            enterFullScreen(with: nil)
        }
    }
}

/** 倍速共享插件（简化版），管理全局倍速设置 */
@MainActor
public final class PlayerSharedSpeedPluginSimple: SharedBasePlugin, PlayerSharedSpeedServiceSimple {

    /** 配置模型类型 */
    public typealias ConfigModelType = EmptyConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerSharedSpeedService"

    /** 当前倍速值 */
    private var _currentSpeed: Float = 1.0
    /** 可用倍速列表 */
    private let _availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    /** 弱引用回调包装 */
    private struct WeakHandler {
        /** 回调 token 弱引用 */
        weak var token: AnyObject?
        /** 回调闭包 */
        let handler: (Float) -> Void
    }
    /** 倍速变化监听器映射 */
    private var speedChangeHandlers: [ObjectIdentifier: WeakHandler] = [:]

    /** 当前倍速 */
    public var currentSpeed: Float {
        return _currentSpeed
    }

    /** 可用倍速列表 */
    public var availableSpeeds: [Float] {
        return _availableSpeeds
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
        print("[PlayerSharedSpeedPlugin] 共享组件已创建，默认倍速: 1.0x")
    }

    /** 设置倍速，验证有效性后通知所有监听者 */
    public func setSpeed(_ speed: Float) {
        guard _availableSpeeds.contains(speed) else {
            print("[PlayerSharedSpeedPlugin] 无效的倍速: \(speed)")
            return
        }

        _currentSpeed = speed

        var keysToRemove: [ObjectIdentifier] = []
        for (key, entry) in speedChangeHandlers {
            if entry.token != nil {
                entry.handler(speed)
            } else {
                keysToRemove.append(key)
            }
        }
        for key in keysToRemove {
            speedChangeHandlers.removeValue(forKey: key)
        }

        print("[PlayerSharedSpeedPlugin] 设置倍速: \(speed)x")
    }

    /** 添加倍速变化监听器，返回用于移除的 token */
    @discardableResult
    public func addSpeedChangeListener(_ handler: @escaping (Float) -> Void) -> AnyObject? {
        let token = NSObject()
        let key = ObjectIdentifier(token)
        speedChangeHandlers[key] = WeakHandler(token: token, handler: handler)
        return token
    }

    /** 移除倍速变化监听器 */
    public func removeSpeedChangeListener(_ token: AnyObject?) {
        guard let token = token else { return }
        speedChangeHandlers.removeValue(forKey: ObjectIdentifier(token))
    }

    /** 获取下一个可用倍速 */
    public func nextSpeed() -> Float {
        guard let index = _availableSpeeds.firstIndex(of: _currentSpeed) else {
            return _currentSpeed
        }
        let nextIndex = (index + 1) % _availableSpeeds.count
        return _availableSpeeds[nextIndex]
    }

    /** 切换到下一个倍速 */
    public func switchToNextSpeed() {
        setSpeed(nextSpeed())
    }
}

/** 循环播放共享插件，管理全局循环播放设置 */
@MainActor
public final class PlayerSharedLoopingPlugin: SharedBasePlugin, PlayerSharedLoopingService {

    /** 配置模型类型 */
    public typealias ConfigModelType = EmptyConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerSharedLoopingService"

    /** 是否启用循环播放 */
    private var _isLooping: Bool = false

    /** 是否循环播放 */
    public var isLooping: Bool {
        return _isLooping
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
        print("[PlayerSharedLoopingPlugin] 共享组件已创建")
    }

    /** 设置循环播放状态 */
    public func setLooping(_ enabled: Bool) {
        _isLooping = enabled
        print("[PlayerSharedLoopingPlugin] 循环播放: \(enabled ? "启用" : "禁用")")
    }

    /** 切换循环播放状态 */
    public func toggleLooping() {
        _isLooping.toggle()
        print("[PlayerSharedLoopingPlugin] 切换循环播放: \(_isLooping)")
    }
}

/** 定时关闭共享插件，管理定时自动停止播放功能 */
@MainActor
public final class PlayerSharedTimedOffPlugin: SharedBasePlugin, PlayerSharedTimedOffService {

    /** 配置模型类型 */
    public typealias ConfigModelType = EmptyConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerSharedTimedOffService"

    /** 定时关闭时间间隔（秒） */
    public private(set) var timedOffInterval: TimeInterval?
    /** 定时器 */
    private var timer: Timer?
    /** 计时开始时间 */
    private var startTime: Date?
    /** 可用的定时间隔列表（秒）：0, 15分钟, 30分钟, 60分钟 */
    private let _availableIntervals: [TimeInterval] = [0, 900, 1800, 3600]

    /** 是否已启用定时关闭 */
    public var isTimedOffEnabled: Bool {
        return timedOffInterval != nil && timedOffInterval! > 0
    }

    /** 剩余时间（秒） */
    public var remainingTime: TimeInterval? {
        guard let start = startTime, let interval = timedOffInterval, interval > 0 else {
            return nil
        }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, interval - elapsed)
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
        print("[PlayerSharedTimedOffPlugin] 共享组件已创建")
    }

    /** 设置定时关闭间隔，0 表示取消 */
    public func setTimedOff(interval: TimeInterval) {
        timer?.invalidate()
        timer = nil

        if interval == 0 {
            timedOffInterval = nil
            startTime = nil
            print("[PlayerSharedTimedOffPlugin] 取消定时关闭")
            return
        }

        timedOffInterval = interval
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleTimedOff()
        }

        print("[PlayerSharedTimedOffPlugin] 设置定时关闭: \(interval / 60) 分钟")
    }

    /** 取消定时关闭 */
    public func cancelTimedOff() {
        setTimedOff(interval: 0)
    }

    /** 处理定时关闭触发 */
    private func handleTimedOff() {
        print("[PlayerSharedTimedOffPlugin] 定时关闭触发")
        timer = nil
        startTime = nil
    }

    /** 可用的定时关闭间隔列表（秒） */
    public var availableIntervals: [TimeInterval] {
        return _availableIntervals
    }

    /** 格式化剩余时间为 MM:SS 格式 */
    public func formatRemainingTime() -> String? {
        guard let remaining = remainingTime else {
            return nil
        }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
