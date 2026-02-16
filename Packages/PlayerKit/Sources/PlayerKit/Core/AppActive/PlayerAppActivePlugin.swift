//
//  PlayerAppActivePlugin.swift
//  playerkit
//
//  前后台处理组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerAppActivePlugin: BasePlugin, PlayerAppActiveService {

    public typealias ConfigModelType = PlayerAppActiveConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _appState: PlayerAppState = .didBecomeActive
    private var wasPlayingBeforeResignActive: Bool = false

    // MARK: - PlayerAppActiveService

    public var appState: PlayerAppState {
        get { _appState }
        set { _appState = newValue }
    }

    public var isAppActive: Bool {
        if case .didBecomeActive = _appState {
            return true
        }
        return false
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

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

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - PlayerAppActiveService

    public func handleAppBecomeActive() {
        _appState = .didBecomeActive
        context?.post(.playerAppDidBecomeActive, sender: self)

        let config = configModel as? PlayerAppActiveConfigModel
        if config?.resumeWhenBecomeActive == true && wasPlayingBeforeResignActive {
            engineService?.play()
        }
    }

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

    @objc private func appDidBecomeActive() {
        handleAppBecomeActive()
    }

    @objc private func appWillResignActive() {
        handleAppResignActive()
    }

    @objc private func appWillEnterForeground() {
        _appState = .willEnterForeground
    }

    @objc private func appDidEnterBackground() {
        _appState = .didEnterBackground
    }
}
