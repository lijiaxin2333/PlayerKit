//
//  PlayerPanelService.swift
//  playerkit
//
//  面板管理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 面板位置

public enum PlayerPanelPosition {
    case top
    case bottom
    case left
    case right
    case center
}

// MARK: - 面板服务

@MainActor
public protocol PlayerPanelService: CCLCompService {

    /// 显示面板
    func showPanel(_ panel: AnyObject, at position: PlayerPanelPosition, animated: Bool)

    /// 隐藏面板
    func hidePanel(_ panel: AnyObject, animated: Bool)

    /// 隐藏所有面板
    func hideAllPanels(animated: Bool)
}

// MARK: - 配置模型

public class PlayerPanelConfigModel {

    /// 是否支持点击背景隐藏面板
    public var tapBackgroundToHide: Bool = true

    public init() {}
}
