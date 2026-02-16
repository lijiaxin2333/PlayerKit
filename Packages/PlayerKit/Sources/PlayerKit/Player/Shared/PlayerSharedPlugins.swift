//
//  PlayerSharedComps.swift
//  playerkit
//
//  Shared 层组件实现
//

import Foundation
import UIKit

// MARK: - 当前播放器组件

/// 当前播放器共享组件
@MainActor
public final class PlayerSharedCurrentPlayerPlugin: SharedBasePlugin, PlayerSharedCurrentPlayerService {

    public typealias ConfigModelType = EmptyConfigModel

    public static let cclServiceName = "PlayerSharedCurrentPlayerService"

    // MARK: - Properties

    private var _currentPlayer: ContextHolder?
    private var _currentPlayerType: PlayerType?

    // MARK: - PlayerSharedCurrentPlayerService

    public var currentPlayer: ContextHolder? {
        return _currentPlayer
    }

    public var currentPlayerType: PlayerType? {
        return _currentPlayerType
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
        print("[PlayerSharedCurrentPlayerPlugin] 共享组件已创建")
    }

    // MARK: - PlayerSharedCurrentPlayerService

    public func setCurrentPlayer(_ player: ContextHolder?, type: PlayerType?) {
        _currentPlayer = player
        _currentPlayerType = type
        print("[PlayerSharedCurrentPlayerPlugin] 设置当前播放器: \(type?.rawValue ?? "unknown")")
    }

    public func clearCurrentPlayer() {
        _currentPlayer = nil
        _currentPlayerType = nil
        print("[PlayerSharedCurrentPlayerPlugin] 清除当前播放器")
    }
}

// MARK: - 全屏组件

/// 全屏共享组件
@MainActor
public final class PlayerSharedFullScreenPlugin: SharedBasePlugin, PlayerSharedFullScreenService {

    public typealias ConfigModelType = EmptyConfigModel

    public static let cclServiceName = "PlayerSharedFullScreenService"

    // MARK: - Properties

    private var _isFullScreen: Bool = false
    private var _fullScreenContainer: UIView?
    private var speedChangeHandlers: [ObjectIdentifier: (Float) -> Void] = [:]
    private var handlerToken: Int = 0

    // MARK: - PlayerSharedFullScreenService

    public var isFullScreen: Bool {
        return _isFullScreen
    }

    public var fullScreenContainer: UIView? {
        return _fullScreenContainer
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
        print("[PlayerSharedFullScreenPlugin] 共享组件已创建")
    }

    // MARK: - PlayerSharedFullScreenService

    public func enterFullScreen(with container: UIView?) {
        _isFullScreen = true
        _fullScreenContainer = container
        print("[PlayerSharedFullScreenPlugin] 进入全屏")
    }

    public func exitFullScreen() {
        _isFullScreen = false
        _fullScreenContainer = nil
        print("[PlayerSharedFullScreenPlugin] 退出全屏")
    }

    public func toggleFullScreen() {
        if _isFullScreen {
            exitFullScreen()
        } else {
            enterFullScreen(with: nil)
        }
    }
}

// MARK: - 倍速组件（简化版）

/// 倍速共享组件（简化版）- 轻量级实现
@MainActor
public final class PlayerSharedSpeedPluginSimple: SharedBasePlugin, PlayerSharedSpeedServiceSimple {

    public typealias ConfigModelType = EmptyConfigModel

    public static let cclServiceName = "PlayerSharedSpeedService"

    // MARK: - Properties

    private var _currentSpeed: Float = 1.0
    private let _availableSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    private struct WeakHandler {
        weak var token: AnyObject?
        let handler: (Float) -> Void
    }
    private var speedChangeHandlers: [ObjectIdentifier: WeakHandler] = [:]

    // MARK: - PlayerSharedSpeedService

    public var currentSpeed: Float {
        return _currentSpeed
    }

    public var availableSpeeds: [Float] {
        return _availableSpeeds
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
        print("[PlayerSharedSpeedPlugin] 共享组件已创建，默认倍速: 1.0x")
    }

    // MARK: - PlayerSharedSpeedService

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

    @discardableResult
    public func addSpeedChangeListener(_ handler: @escaping (Float) -> Void) -> AnyObject? {
        let token = NSObject()
        let key = ObjectIdentifier(token)
        speedChangeHandlers[key] = WeakHandler(token: token, handler: handler)
        return token
    }

    public func removeSpeedChangeListener(_ token: AnyObject?) {
        guard let token = token else { return }
        speedChangeHandlers.removeValue(forKey: ObjectIdentifier(token))
    }

    public func nextSpeed() -> Float {
        guard let index = _availableSpeeds.firstIndex(of: _currentSpeed) else {
            return _currentSpeed
        }
        let nextIndex = (index + 1) % _availableSpeeds.count
        return _availableSpeeds[nextIndex]
    }

    public func switchToNextSpeed() {
        setSpeed(nextSpeed())
    }
}

// MARK: - 循环播放组件

/// 循环播放共享组件
@MainActor
public final class PlayerSharedLoopingPlugin: SharedBasePlugin, PlayerSharedLoopingService {

    public typealias ConfigModelType = EmptyConfigModel

    public static let cclServiceName = "PlayerSharedLoopingService"

    // MARK: - Properties

    private var _isLooping: Bool = false

    // MARK: - PlayerSharedLoopingService

    public var isLooping: Bool {
        return _isLooping
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
        print("[PlayerSharedLoopingPlugin] 共享组件已创建")
    }

    // MARK: - PlayerSharedLoopingService

    public func setLooping(_ enabled: Bool) {
        _isLooping = enabled
        print("[PlayerSharedLoopingPlugin] 循环播放: \(enabled ? "启用" : "禁用")")
    }

    public func toggleLooping() {
        _isLooping.toggle()
        print("[PlayerSharedLoopingPlugin] 切换循环播放: \(_isLooping)")
    }
}

// MARK: - 定时关闭组件

/// 定时关闭共享组件
@MainActor
public final class PlayerSharedTimedOffPlugin: SharedBasePlugin, PlayerSharedTimedOffService {

    public typealias ConfigModelType = EmptyConfigModel

    public static let cclServiceName = "PlayerSharedTimedOffService"

    // MARK: - Properties

    public private(set) var timedOffInterval: TimeInterval?
    private var timer: Timer?
    private var startTime: Date?
    private let _availableIntervals: [TimeInterval] = [0, 900, 1800, 3600] // 0, 15, 30, 60 分钟

    // MARK: - PlayerSharedTimedOffService

    public var isTimedOffEnabled: Bool {
        return timedOffInterval != nil && timedOffInterval! > 0
    }

    public var remainingTime: TimeInterval? {
        guard let start = startTime, let interval = timedOffInterval, interval > 0 else {
            return nil
        }
        let elapsed = Date().timeIntervalSince(start)
        return max(0, interval - elapsed)
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
        print("[PlayerSharedTimedOffPlugin] 共享组件已创建")
    }

    // MARK: - PlayerSharedTimedOffService

    public func setTimedOff(interval: TimeInterval) {
        // 取消之前的定时器
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

        // 创建新的定时器
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.handleTimedOff()
        }

        print("[PlayerSharedTimedOffPlugin] 设置定时关闭: \(interval / 60) 分钟")
    }

    public func cancelTimedOff() {
        setTimedOff(interval: 0)
    }

    // MARK: - Private Methods

    private func handleTimedOff() {
        print("[PlayerSharedTimedOffPlugin] 定时关闭触发")
        timer = nil
        startTime = nil
        // 触发关闭事件（通过外部监听处理）
        // 注意：共享组件没有直接的事件发布能力
        // 使用者应该监听 timedOffInterval 的变化
    }

    // MARK: - Public Methods

    /// 可用的定时关闭间隔（秒）
    public var availableIntervals: [TimeInterval] {
        return _availableIntervals
    }

    /// 格式化剩余时间
    public func formatRemainingTime() -> String? {
        guard let remaining = remainingTime else {
            return nil
        }
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
