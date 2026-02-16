//
//  PlayerSpeedPlugin.swift
//  playerkit
//
//  倍速播放组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 倍速播放插件
 */
@MainActor
public final class PlayerSpeedPlugin: BasePlugin, PlayerSpeedService {

    public typealias ConfigModelType = PlayerSpeedConfigModel

    // MARK: - Properties

    /**
     * 引擎服务依赖
     */
    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    /**
     * 当前倍速
     */
    private var _currentSpeed: Float = 1.0
    /**
     * 可用的倍速列表
     */
    private var _availableSpeeds: [PlayerSpeedOption] = []

    // MARK: - PlayerSpeedService

    /**
     * 当前倍速
     */
    public var currentSpeed: Float {
        get { _currentSpeed }
        set {
            setSpeed(newValue)
        }
    }

    /**
     * 可用的倍速列表
     */
    public var availableSpeeds: [PlayerSpeedOption] {
        get { _availableSpeeds }
        set { _availableSpeeds = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    /**
     * 应用配置
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerSpeedConfigModel else { return }

        _availableSpeeds = config.availableSpeeds
        _currentSpeed = config.defaultSpeed
    }

    // MARK: - PlayerSpeedService

    /**
     * 设置倍速（数值）
     */
    public func setSpeed(_ speed: Float) {
        _currentSpeed = speed
        engineService?.rate = speed
        context?.post(.playerSpeedDidChange, object: speed, sender: self)
    }

    /**
     * 设置倍速（选项）
     */
    public func setSpeed(_ option: PlayerSpeedOption) {
        setSpeed(option.rate)
    }
}
