//
//  PlayerTrackerPlugin.swift
//  playerkit
//
//  埋点组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerTrackerPlugin: BasePlugin, PlayerTrackerService {

    public typealias ConfigModelType = PlayerTrackerConfigModel

    // MARK: - Properties

    private var trackerNodes: [PlayerTrackerNodeName: AnyObject] = [:]

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerTrackerService

    public func registerTrackerNode(_ node: AnyObject) {
        guard let nodeProtocol = node as? PlayerTrackerNodeProtocol else {
            print("[PlayerTrackerPlugin] ⚠️ 节点未实现 PlayerTrackerNodeProtocol: \(node)")
            return
        }

        let nodeName = type(of: nodeProtocol).trackerNodeName
        trackerNodes[nodeName] = node

        print("[PlayerTrackerPlugin] ✓ 注册节点: \(nodeName)")
    }

    public func unregisterTrackerNode(_ node: AnyObject) {
        guard let nodeProtocol = node as? PlayerTrackerNodeProtocol else { return }

        let nodeName = type(of: nodeProtocol).trackerNodeName
        trackerNodes.removeValue(forKey: nodeName)

        print("[PlayerTrackerPlugin] ✗ 移除节点: \(nodeName)")
    }

    public func sendEvent(_ eventName: String, params: [String: Any]? = nil) {
        guard let config = configModel as? PlayerTrackerConfigModel, config.enabled else { return }

        var finalParams = params ?? [:]

        // 自动添加所有节点的参数
        for (nodeName, node) in trackerNodes {
            if let trackerNode = node as? PlayerTrackerNodeProtocol,
               let nodeParams = trackerNode.trackerNodeParams() {
                finalParams.merge(nodeParams) { _, new in new }
            }
        }

        // 打印埋点信息
        print("[PlayerTrackerPlugin] 📊 埋点上报")
        print("  ├─ 事件: \(eventName)")
        print("  └─ 参数: \(finalParams)")
    }

    public func sendEvent(_ eventName: String,
                   selectKeys: [PlayerTrackerNodeName]? = nil,
                   paramsMaker: (([String: Any]) -> Void)? = nil) {
        guard let config = configModel as? PlayerTrackerConfigModel, config.enabled else { return }

        var finalParams: [String: Any] = [:]

        // 选择指定节点的参数
        if let selectKeys = selectKeys {
            for nodeName in selectKeys {
                if let node = trackerNodes[nodeName],
                   let trackerNode = node as? PlayerTrackerNodeProtocol,
                   let nodeParams = trackerNode.trackerNodeParams() {
                    finalParams.merge(nodeParams) { _, new in new }
                }
            }
        }

        // 允许修改参数
        paramsMaker?(finalParams)

        // 打印埋点信息
        print("[PlayerTrackerPlugin] 📊 埋点上报")
        print("  ├─ 事件: \(eventName)")
        if let selectKeys = selectKeys {
            print("  ├─ 节点: \(selectKeys)")
        }
        print("  └─ 参数: \(finalParams)")
    }

    public func paramsForNodes(_ nodeNames: [PlayerTrackerNodeName]) -> [String: Any] {
        var params: [String: Any] = [:]

        for nodeName in nodeNames {
            if let node = trackerNodes[nodeName],
               let trackerNode = node as? PlayerTrackerNodeProtocol,
               let nodeParams = trackerNode.trackerNodeParams() {
                params.merge(nodeParams) { _, new in new }
            }
        }

        return params
    }

    public func hasTrackerNode(_ nodeName: PlayerTrackerNodeName) -> Bool {
        return trackerNodes[nodeName] != nil
    }
}
