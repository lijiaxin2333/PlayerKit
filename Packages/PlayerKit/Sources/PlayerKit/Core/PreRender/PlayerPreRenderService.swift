//
//  PlayerPreRenderService.swift
//  playerkit
//
//  预渲染服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 预渲染服务

@MainActor
public protocol PlayerPreRenderService: PluginService {

    /// 是否启用预渲染
    var isPreRenderEnabled: Bool { get set }

    /// 预渲染 URL
    func prerenderURL(_ url: URL)

    /// 取消预渲染
    func cancelPrerender()
}

// MARK: - 配置模型

public class PlayerPreRenderConfigModel {

    /// 是否启用预渲染
    public var enabled: Bool = false

    /// 预渲染超时时间
    public var timeout: TimeInterval = 10.0

    public init() {}
}
