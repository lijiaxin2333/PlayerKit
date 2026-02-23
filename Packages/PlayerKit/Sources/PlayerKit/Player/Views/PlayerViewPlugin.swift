//
//  PlayerViewPlugin.swift
//  playerkit
//
//  播放器视图插件
//

import Foundation
import UIKit

/// 播放器视图配置模型
public class PlayerViewConfigModel {

    /// 是否显示背景色
    public var showBackgroundColor: Bool = true
    /// 背景颜色
    public var backgroundColor: UIColor = .black

    public init() {}
}

/// 播放器视图插件，提供播放器渲染视图
@MainActor
public final class PlayerViewPlugin: BasePlugin, PlayerViewService {

    public typealias ConfigModelType = PlayerViewConfigModel

    public static let cclServiceName = "PlayerViewService"

    private var config: PlayerViewConfigModel = PlayerViewConfigModel()

    /// 播放器渲染视图
    public private(set) var playerView: UIView?

    /// 引擎服务依赖
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    public required override init() {
        self.config = PlayerViewConfigModel()
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 监听引擎创建事件
        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.setupPlayerView()
        }

        // 尝试立即设置
        setupPlayerView()
    }

    private func setupPlayerView() {
        guard playerView == nil else { return }
        guard let pv = engineService?.playerView else { return }

        if config.showBackgroundColor {
            pv.backgroundColor = config.backgroundColor
        }

        self.playerView = pv

        // 发送视图创建事件
        context?.post(.playerViewDidCreate, object: pv, sender: self)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerViewConfigModel else { return }
        self.config = configModel

        if config.showBackgroundColor {
            playerView?.backgroundColor = config.backgroundColor
        }
    }
}

// MARK: - Event

public extension Event {
    /// 播放器视图创建完成事件
    static let playerViewDidCreate: Event = "PlayerViewDidCreate"
}
