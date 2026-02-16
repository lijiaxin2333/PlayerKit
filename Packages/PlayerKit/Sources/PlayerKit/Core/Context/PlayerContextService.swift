//
//  PlayerContextService.swift
//  playerkit
//
//  Context 管理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Context 管理服务

@MainActor
public protocol PlayerContextService: PluginService {

    /// 获取 Context
    var playerContext: ContextProtocol? { get }

    /// 添加子 Context
    func addSubContext(_ context: PublicContext)

    /// 移除子 Context
    func removeSubContext(_ context: PublicContext)

    /// 绑定共享 Context
    func bindSharedContext(_ context: SharedContextProtocol)
}

// MARK: - 配置模型

public class PlayerContextConfigModel {

    /// 共享 Context 名称
    public var sharedContextName: String?

    public init() {}
}
