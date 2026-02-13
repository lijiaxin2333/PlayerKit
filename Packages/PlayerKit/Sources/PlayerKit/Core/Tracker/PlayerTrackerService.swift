//
//  PlayerTrackerService.swift
//  playerkit
//
//  埋点服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 埋点节点名称

public typealias PlayerTrackerNodeName = String

// MARK: - 预设节点

public extension PlayerTrackerNodeName {
    /// APP 级信息
    static let app = "PlayerTrackerNodeAPP"
    /// 上下文信息
    static let context = "PlayerTrackerNodeContext"
    /// 视频信息
    static let content = "PlayerTrackerNodeContent"
    /// 播放器状态
    static let player = "PlayerTrackerNodePlayer"
}

// MARK: - 埋点节点协议

public protocol PlayerTrackerNodeProtocol: AnyObject {

    /// 节点名称
    static var trackerNodeName: PlayerTrackerNodeName { get }

    /// 节点提供的参数
    func trackerNodeParams() -> [String: Any]?
}

// MARK: - 埋点服务

@MainActor
public protocol PlayerTrackerService: CCLCompService {

    /// 注册埋点节点
    func registerTrackerNode(_ node: AnyObject)

    /// 移除埋点节点
    func unregisterTrackerNode(_ node: AnyObject)

    /// 发送埋点事件
    /// - Parameters:
    ///   - eventName: 事件名称
    ///   - params: 事件参数
    func sendEvent(_ eventName: String, params: [String: Any]?)

    /// 发送埋点事件，选择指定节点的参数
    /// - Parameters:
    ///   - eventName: 事件名称
    ///   - selectKeys: 选择要包含的节点参数
    ///   - paramsMaker: 参数构建回调
    func sendEvent(_ eventName: String,
                   selectKeys: [PlayerTrackerNodeName]?,
                   paramsMaker: (([String: Any]) -> Void)?)

    /// 获取指定节点的参数
    func paramsForNodes(_ nodeNames: [PlayerTrackerNodeName]) -> [String: Any]

    /// 检查节点是否已注册
    func hasTrackerNode(_ nodeName: PlayerTrackerNodeName) -> Bool
}

// MARK: - 配置模型

public class PlayerTrackerConfigModel {

    /// 是否启用埋点
    public var enabled: Bool = true

    /// 埋点上报地址
    public var reportURL: URL?

    public init() {}
}
