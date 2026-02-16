//
//  PlayerContextPlugin.swift
//  playerkit
//
//  Context 管理组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * Context 管理插件，提供子 Context 和共享 Context 的管理能力
 */
@MainActor
public final class PlayerContextPlugin: BasePlugin, PlayerContextService {

    /**
     * 配置模型类型
     */
    public typealias ConfigModelType = PlayerContextConfigModel

    // MARK: - Properties

    /**
     * 播放器 Context
     */
    public var playerContext: ContextProtocol? {
        return context
    }

    // MARK: - Initialization

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成，绑定共享 Context
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        if let config = configModel as? PlayerContextConfigModel,
           let sharedName = config.sharedContextName {
            let shared = SharedContext.context(withName: sharedName)
            (context as? PublicContext)?.bindSharedContext(shared)
        }
    }

    // MARK: - PlayerContextService

    /**
     * 添加子 Context
     */
    public func addSubContext(_ context: PublicContext) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.addSubContext(context)
    }

    /**
     * 移除子 Context
     */
    public func removeSubContext(_ context: PublicContext) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.removeSubContext(context)
    }

    /**
     * 绑定共享 Context
     */
    public func bindSharedContext(_ context: SharedContextProtocol) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.bindSharedContext(context)
    }
}
