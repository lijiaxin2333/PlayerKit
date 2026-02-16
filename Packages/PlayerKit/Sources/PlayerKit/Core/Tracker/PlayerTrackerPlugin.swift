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
/**
 * 埋点插件，管理埋点节点注册与事件上报，支持多节点参数聚合
 */
public final class PlayerTrackerPlugin: BasePlugin, PlayerTrackerService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerTrackerConfigModel

    /** 已注册的埋点节点，按节点名索引 */
    private var trackerNodes: [PlayerTrackerNodeName: AnyObject] = [:]

    public required override init() {
        super.init()
    }

    /**
     * 应用配置模型
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    /**
     * 注册埋点节点
     */
    public func registerTrackerNode(_ node: AnyObject) {
        guard let nodeProtocol = node as? PlayerTrackerNodeProtocol else {
            print("[PlayerTrackerPlugin] ⚠️ 节点未实现 PlayerTrackerNodeProtocol: \(node)")
            return
        }

        let nodeName = type(of: nodeProtocol).trackerNodeName
        trackerNodes[nodeName] = node

        print("[PlayerTrackerPlugin] ✓ 注册节点: \(nodeName)")
    }

    /**
     * 移除埋点节点
     */
    public func unregisterTrackerNode(_ node: AnyObject) {
        guard let nodeProtocol = node as? PlayerTrackerNodeProtocol else { return }

        let nodeName = type(of: nodeProtocol).trackerNodeName
        trackerNodes.removeValue(forKey: nodeName)

        print("[PlayerTrackerPlugin] ✗ 移除节点: \(nodeName)")
    }

    /**
     * 发送埋点事件，自动合并所有节点的参数
     */
    public func sendEvent(_ eventName: String, params: [String: Any]? = nil) {
        guard let config = configModel as? PlayerTrackerConfigModel, config.enabled else { return }

        var finalParams = params ?? [:]

        for (nodeName, node) in trackerNodes {
            if let trackerNode = node as? PlayerTrackerNodeProtocol,
               let nodeParams = trackerNode.trackerNodeParams() {
                finalParams.merge(nodeParams) { _, new in new }
            }
        }

        print("[PlayerTrackerPlugin] 📊 埋点上报")
        print("  ├─ 事件: \(eventName)")
        print("  └─ 参数: \(finalParams)")
    }

    /**
     * 发送埋点事件，可指定节点并自定义参数
     */
    public func sendEvent(_ eventName: String,
                   selectKeys: [PlayerTrackerNodeName]? = nil,
                   paramsMaker: (([String: Any]) -> Void)? = nil) {
        guard let config = configModel as? PlayerTrackerConfigModel, config.enabled else { return }

        var finalParams: [String: Any] = [:]

        if let selectKeys = selectKeys {
            for nodeName in selectKeys {
                if let node = trackerNodes[nodeName],
                   let trackerNode = node as? PlayerTrackerNodeProtocol,
                   let nodeParams = trackerNode.trackerNodeParams() {
                    finalParams.merge(nodeParams) { _, new in new }
                }
            }
        }

        paramsMaker?(finalParams)

        print("[PlayerTrackerPlugin] 📊 埋点上报")
        print("  ├─ 事件: \(eventName)")
        if let selectKeys = selectKeys {
            print("  ├─ 节点: \(selectKeys)")
        }
        print("  └─ 参数: \(finalParams)")
    }

    /**
     * 获取指定节点的参数聚合结果
     */
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

    /**
     * 检查指定节点是否已注册
     */
    public func hasTrackerNode(_ nodeName: PlayerTrackerNodeName) -> Bool {
        return trackerNodes[nodeName] != nil
    }
}
