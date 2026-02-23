//
//  PlayerCoverMaskService.swift
//  playerkit
//
//  遮罩视图服务协议
//

import Foundation
import AVFoundation
import UIKit
import PlayerKit

/**
 * 遮罩视图服务协议
 */
@MainActor
public protocol PlayerCoverMaskService: PluginService {

    /**
     * 显示遮罩
     */
    func showCoverMask(_ mask: AnyObject)

    /**
     * 隐藏遮罩
     */
    func hideCoverMask(_ mask: AnyObject)

    /**
     * 隐藏所有遮罩
     */
    func hideAllCoverMasks()
}

/**
 * 遮罩配置模型
 */
public class PlayerCoverMaskConfigModel {

    /**
     * 是否允许点击穿透
     */
    public var allowTouchThrough: Bool = false

    /**
     * 初始化配置
     */
    public init() {}
}
