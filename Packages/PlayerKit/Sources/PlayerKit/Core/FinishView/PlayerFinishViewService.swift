//
//  PlayerFinishViewService.swift
//  playerkit
//
//  播放结束视图服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 播放结束视图服务

@MainActor
public protocol PlayerFinishViewService: PluginService {

    /// 显示结束视图
    func showFinishView()

    /// 隐藏结束视图
    func hideFinishView()
}

// MARK: - 配置模型

public class PlayerFinishViewConfigModel {

    /// 是否自动显示结束视图
    public var autoShow: Bool = true

    public init() {}
}
