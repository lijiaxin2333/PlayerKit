//
//  PlayerContextComp.swift
//  playerkit
//
//  Context 管理组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerContextComp: CCLBaseComp, PlayerContextService {

    public typealias ConfigModelType = PlayerContextConfigModel

    // MARK: - Properties

    public var playerContext: CCLContextProtocol? {
        return context
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        // 绑定共享 Context
        if let config = configModel as? PlayerContextConfigModel,
           let sharedName = config.sharedContextName {
            let shared = CCLSharedContext.context(withName: sharedName)
            (context as? CCLPublicContext)?.bindSharedContext(shared)
        }
    }

    // MARK: - PlayerContextService

    public func addSubContext(_ context: CCLPublicContext) {
        guard let playerContext = self.context as? CCLPublicContext else { return }
        playerContext.addSubContext(context)
    }

    public func removeSubContext(_ context: CCLPublicContext) {
        guard let playerContext = self.context as? CCLPublicContext else { return }
        playerContext.removeSubContext(context)
    }

    public func bindSharedContext(_ context: CCLSharedContextProtocol) {
        guard let playerContext = self.context as? CCLPublicContext else { return }
        playerContext.bindSharedContext(context)
    }
}
