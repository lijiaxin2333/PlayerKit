//
//  PlayerContextPlugin.swift
//  playerkit
//
//  Context 管理组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerContextPlugin: BasePlugin, PlayerContextService {

    public typealias ConfigModelType = PlayerContextConfigModel

    // MARK: - Properties

    public var playerContext: ContextProtocol? {
        return context
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 绑定共享 Context
        if let config = configModel as? PlayerContextConfigModel,
           let sharedName = config.sharedContextName {
            let shared = SharedContext.context(withName: sharedName)
            (context as? PublicContext)?.bindSharedContext(shared)
        }
    }

    // MARK: - PlayerContextService

    public func addSubContext(_ context: PublicContext) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.addSubContext(context)
    }

    public func removeSubContext(_ context: PublicContext) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.removeSubContext(context)
    }

    public func bindSharedContext(_ context: SharedContextProtocol) {
        guard let playerContext = self.context as? PublicContext else { return }
        playerContext.bindSharedContext(context)
    }
}
