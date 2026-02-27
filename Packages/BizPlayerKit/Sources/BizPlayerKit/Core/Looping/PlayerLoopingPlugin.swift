//
//  PlayerLoopingPlugin.swift
//  playerkit
//
//  循环播放组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 循环播放插件
 * - 只负责当前视频的循环，列表循环由列表层负责
 */
@MainActor
public final class PlayerLoopingPlugin: BasePlugin, PlayerLoopingService {

    public typealias ConfigModelType = PlayerLoopingConfigModel

    // MARK: - Properties

    /**
     * 引擎服务依赖
     */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /**
     * 循环模式
     */
    private var _loopingMode: PlayerLoopingMode = .none

    // MARK: - PlayerLoopingService

    /**
     * 循环模式
     */
    public var loopingMode: PlayerLoopingMode {
        get { _loopingMode }
        set {
            _loopingMode = newValue
            engineService?.isLooping = (newValue == .loop)
            context?.post(.playerLoopingDidChange, object: newValue, sender: self)
        }
    }

    /**
     * 是否循环播放
     */
    public var isLooping: Bool {
        return loopingMode == .loop
    }

    // MARK: - Initialization

    public required init() {
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

        guard let config = configModel as? PlayerLoopingConfigModel else { return }

        self.loopingMode = config.defaultMode
    }

    // MARK: - PlayerLoopingService

    /**
     * 切换循环模式（none <-> loop）
     */
    public func toggleLooping() {
        switch loopingMode {
        case .none:
            loopingMode = .loop
        case .loop:
            loopingMode = .none
        }
    }

    /**
     * 设置循环模式
     */
    public func setLoopingMode(_ mode: PlayerLoopingMode) {
        loopingMode = mode
    }
}
