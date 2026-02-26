import Foundation

import UIKit
import PlayerKit

/**
 * 面板显示位置枚举
 */
public enum PlayerPanelPosition {
    /** 顶部 */
    case top
    /** 底部 */
    case bottom
    /** 左侧 */
    case left
    /** 右侧 */
    case right
    /** 居中 */
    case center
}

/**
 * 面板管理服务协议
 */
@MainActor
public protocol PlayerPanelService: PluginService {

    /**
     * 显示面板
     */
    func showPanel(_ panel: AnyObject, at position: PlayerPanelPosition, animated: Bool)

    /**
     * 隐藏面板
     */
    func hidePanel(_ panel: AnyObject, animated: Bool)

    /**
     * 隐藏所有面板
     */
    func hideAllPanels(animated: Bool)
}

/**
 * 面板配置模型
 */
public class PlayerPanelConfigModel {

    /** 是否支持点击背景隐藏面板 */
    public var tapBackgroundToHide: Bool = true

    /**
     * 初始化
     */
    public init() {}
}
