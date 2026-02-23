//
//  PlayerControlViewService.swift
//  playerkit
//
//  播控视图服务协议
//

import Foundation
import AVFoundation
import UIKit
import PlayerKit

/**
 * 播控视图协议
 */
public protocol PlayerControlViewProtocol: UIView {

    /**
     * 显示或隐藏播控
     */
    func setShowControl(_ show: Bool, animated: Bool)

    /**
     * 锁定或解锁播控
     */
    func setLocked(_ locked: Bool)

    /**
     * 更新播控状态
     */
    func updateControlState()
}

/**
 * 播控视图服务协议
 */
@MainActor
public protocol PlayerControlViewService: PluginService {

    /**
     * 播控视图
     */
    var controlView: UIView? { get }

    /**
     * 是否显示播控
     */
    var isShowControl: Bool { get set }

    /**
     * 是否锁定播控
     */
    var isLocked: Bool { get set }

    /**
     * 播控首次加载完成
     */
    var controlViewDidLoad: Bool { get }

    /**
     * 显示播控
     */
    func showControl(animated: Bool)

    /**
     * 隐藏播控
     */
    func hideControl(animated: Bool)

    /**
     * 切换播控显示
     */
    func toggleControl(animated: Bool)

    /**
     * 锁定播控
     */
    func lockControl()

    /**
     * 解锁播控
     */
    func unlockControl()

    /**
     * 强制显示播控
     */
    func forceShowControl(_ show: Bool, forKey: String)

    /**
     * 恢复播控显示状态
     */
    func resumeControl(forKey: String)

    /**
     * 更新播控模板
     */
    func updateControlTemplate(_ templateClass: AnyClass?)
}

/**
 * 播控视图配置模型
 */
public class PlayerControlViewConfigModel {

    /**
     * 自动隐藏时间间隔（秒）
     */
    public var autoHideInterval: TimeInterval = 3.0

    /**
     * 是否支持锁定
     */
    public var supportLock: Bool = true

    /**
     * 是否支持点击隐藏
     */
    public var supportTapToHide: Bool = true

    /**
     * 初始化配置
     */
    public init() {}
}
