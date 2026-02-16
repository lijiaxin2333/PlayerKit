//
//  PlayerLoopingPlugin.swift
//  playerkit
//
//  循环播放组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerLoopingPlugin: BasePlugin, PlayerLoopingService {

    public typealias ConfigModelType = PlayerLoopingConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _loopingMode: PlayerLoopingMode = .none

    // MARK: - PlayerLoopingService

    public var loopingMode: PlayerLoopingMode {
        get { _loopingMode }
        set {
            _loopingMode = newValue
            engineService?.isLooping = (newValue != .none)
            context?.post(.playerLoopingDidChange, object: newValue, sender: self)
        }
    }

    public var isLooping: Bool {
        return loopingMode != .none
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

        guard let config = configModel as? PlayerLoopingConfigModel else { return }

        _loopingMode = config.defaultMode
        engineService?.isLooping = (config.defaultMode != .none)
    }

    // MARK: - PlayerLoopingService

    public func toggleLooping() {
        switch loopingMode {
        case .none:
            loopingMode = .one
        case .one:
            loopingMode = .all
        case .all:
            loopingMode = .none
        }
    }

    public func setLoopingMode(_ mode: PlayerLoopingMode) {
        loopingMode = mode
    }
}
