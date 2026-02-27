//
//  PlayerFinishViewService.swift
//  playerkit
//
//  播放结束视图服务协议
//

import Foundation

import UIKit
import BizPlayerKit

/**
 * 播放结束视图服务协议
 */
@MainActor
public protocol PlayerFinishViewService: PluginService {

    /**
     * 显示结束视图
     */
    func showFinishView()

    /**
     * 隐藏结束视图
     */
    func hideFinishView()
}

/**
 * 播放结束视图配置模型
 */
public class PlayerFinishViewConfigModel {

    /**
     * 是否自动显示结束视图
     */
    public var autoShow: Bool = true

    /**
     * 初始化配置
     */
    public init() {}
}
