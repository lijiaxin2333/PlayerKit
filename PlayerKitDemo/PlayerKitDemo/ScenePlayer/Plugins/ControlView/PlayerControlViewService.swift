//
//  PlayerControlViewService.swift
//  playerkit
//
//  播控视图服务协议
//

import Foundation
import UIKit
import PlayerKit

// MARK: - Control View Events

public extension Event {
    /// 播控模板更新
    static let playerControlViewTemplateChanged: Event = "PlayerControlViewTemplateChanged"
    /// 播控初次加载完成（粘性事件）
    static let playerControlViewDidLoadSticky: Event = "PlayerControlViewDidLoadSticky"
    /// 播控显示状态更新
    static let playerShowControl: Event = "PlayerShowControl"
    /// 播控锁屏状态更新
    static let playerControlViewDidChangeLock: Event = "PlayerControlViewDidChangeLock"
    /// 单击播控
    static let playerControlViewSingleTap: Event = "PlayerControlViewSingleTap"
    /// 播控 Focus 状态更新
    static let playerControlViewDidChangeFocus: Event = "PlayerControlViewDidChangeFocus"
}

// MARK: - Control View Protocol

/// 播控视图协议
public protocol PlayerControlViewProtocol: UIView {

    /// 显示或隐藏播控
    func setShowControl(_ show: Bool, animated: Bool)

    /// 锁定或解锁播控
    func setLocked(_ locked: Bool)

    /// 更新播控状态
    func updateControlState()
}

// MARK: - Control View Service Protocol

@MainActor
public protocol PlayerControlViewService: PluginService {

    /// 播控视图
    var controlView: UIView? { get }

    /// 是否显示播控
    var isShowControl: Bool { get set }

    /// 是否锁定播控
    var isLocked: Bool { get set }

    /// 播控首次加载完成
    var controlViewDidLoad: Bool { get }

    /// 显示播控
    func showControl(animated: Bool)

    /// 隐藏播控
    func hideControl(animated: Bool)

    /// 切换播控显示
    func toggleControl(animated: Bool)

    /// 锁定播控
    func lockControl()

    /// 解锁播控
    func unlockControl()

    /// 强制显示播控
    func forceShowControl(_ show: Bool, forKey: String)

    /// 恢复播控显示状态
    func resumeControl(forKey: String)

    /// 更新播控模板
    func updateControlTemplate(_ templateClass: AnyClass?)
}

// MARK: - Control View Config Model

/// 播控视图配置模型
public class PlayerControlViewConfigModel {

    /// 自动隐藏时间间隔（秒）
    public var autoHideInterval: TimeInterval = 3.0

    public init() {}
}
