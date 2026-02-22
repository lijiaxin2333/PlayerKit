//
//  PlayerAppActivePlugin.swift
//  playerkit
//
//  前后台处理组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 应用前后台处理插件，监听应用前后台切换并管理播放状态
 */
@MainActor
public final class PlayerAppActivePlugin: BasePlugin, PlayerAppActiveService {

    /**
     * 配置模型类型
     */
    public typealias ConfigModelType = PlayerAppActiveConfigModel

    // MARK: - Properties

    /**
     * 播放引擎核心服务
     */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /**
     * 当前应用状态
     */
    private var _appState: PlayerAppState = .didBecomeActive

    /**
     * 进入后台前是否正在播放
     */
    private var wasPlayingBeforeResignActive: Bool = false

    // MARK: - PlayerAppActiveService

    /**
     * 当前应用状态
     */
    public var appState: PlayerAppState {
        get { _appState }
        set { _appState = newValue }
    }

    /**
     * 应用是否在前台
     */
    public var isAppActive: Bool {
        if case .didBecomeActive = _appState {
            return true
        }
        return false
    }

    // MARK: - Initialization

    /**
     * 初始化插件
     */
    public required init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成，注册前后台通知监听
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    /**
     * 插件即将卸载，移除通知监听
     */
    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - PlayerAppActiveService

    /**
     * 处理应用进入前台
     */
    public func handleAppBecomeActive() {
        _appState = .didBecomeActive
        context?.post(.playerAppDidBecomeActive, sender: self)

        let config = configModel as? PlayerAppActiveConfigModel
        if config?.resumeWhenBecomeActive == true && wasPlayingBeforeResignActive {
            engineService?.play()
        }
    }

    /**
     * 处理应用进入后台
     */
    public func handleAppResignActive() {
        _appState = .didResignActive
        context?.post(.playerAppDidResignActive, sender: self)

        let config = configModel as? PlayerAppActiveConfigModel
        if config?.pauseWhenResignActive == true {
            wasPlayingBeforeResignActive = engineService?.playbackState == .playing
            engineService?.pause()
        }
    }

    // MARK: - Notification Handlers

    /**
     * 应用已激活通知回调
     */
    @objc private func appDidBecomeActive() {
        handleAppBecomeActive()
    }

    /**
     * 应用即将失活通知回调
     */
    @objc private func appWillResignActive() {
        handleAppResignActive()
    }

    /**
     * 应用即将进入前台通知回调
     */
    @objc private func appWillEnterForeground() {
        _appState = .willEnterForeground
    }

    /**
     * 应用已进入后台通知回调
     */
    @objc private func appDidEnterBackground() {
        _appState = .didEnterBackground
    }
}
