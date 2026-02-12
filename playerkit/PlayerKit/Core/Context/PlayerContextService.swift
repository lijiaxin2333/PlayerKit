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
public protocol PlayerContextService: CCLCompService {

    /// 获取 Context
    var playerContext: CCLContextProtocol? { get }

    /// 添加子 Context
    func addSubContext(_ context: CCLPublicContext)

    /// 移除子 Context
    func removeSubContext(_ context: CCLPublicContext)

    /// 绑定共享 Context
    func bindSharedContext(_ context: CCLSharedContextProtocol)
}

// MARK: - 配置模型

public class PlayerContextConfigModel {

    /// 共享 Context 名称
    public var sharedContextName: String?

    public init() {}
}
