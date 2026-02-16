//
//  PlayerPreRenderService.swift
//  playerkit
//
//  预渲染服务协议
//

import Foundation
import AVFoundation
import UIKit

/**
 * 预渲染服务协议
 */
@MainActor
public protocol PlayerPreRenderService: PluginService {

    /** 是否启用预渲染 */
    var isPreRenderEnabled: Bool { get set }

    /**
     * 对指定 URL 进行预渲染
     */
    func prerenderURL(_ url: URL)

    /**
     * 取消当前预渲染
     */
    func cancelPrerender()
}

/**
 * 预渲染配置模型
 */
public class PlayerPreRenderConfigModel {

    /** 是否启用预渲染 */
    public var enabled: Bool = false

    /** 预渲染超时时间 */
    public var timeout: TimeInterval = 10.0

    /**
     * 初始化配置
     */
    public init() {}
}
