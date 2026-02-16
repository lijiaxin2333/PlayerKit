//
//  PlayerSpeedPlugin.swift
//  playerkit
//
//  倍速播放组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerSpeedPlugin: BasePlugin, PlayerSpeedService {

    public typealias ConfigModelType = PlayerSpeedConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _currentSpeed: Float = 1.0
    private var _availableSpeeds: [PlayerSpeedOption] = []

    // MARK: - PlayerSpeedService

    public var currentSpeed: Float {
        get { _currentSpeed }
        set {
            setSpeed(newValue)
        }
    }

    public var availableSpeeds: [PlayerSpeedOption] {
        get { _availableSpeeds }
        set { _availableSpeeds = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerSpeedConfigModel else { return }

        _availableSpeeds = config.availableSpeeds
        _currentSpeed = config.defaultSpeed
    }

    // MARK: - PlayerSpeedService

    public func setSpeed(_ speed: Float) {
        _currentSpeed = speed
        engineService?.rate = speed
        context?.post(.playerSpeedDidChange, object: speed, sender: self)
    }

    public func setSpeed(_ option: PlayerSpeedOption) {
        setSpeed(option.rate)
    }
}
