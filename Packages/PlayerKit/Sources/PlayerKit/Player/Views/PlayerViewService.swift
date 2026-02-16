//
//  PlayerViewService.swift
//  playerkit
//
//  播放器视图服务协议
//

import Foundation
import UIKit

// MARK: - 播放器 ActionView 协议

@MainActor
public protocol PlayerActionViewProtocol: AnyObject {

    /// 添加视图到指定层级
    /// - Parameters:
    ///   - view: 要添加的视图
    ///   - viewType: 视图类型
    func addSubview(_ view: UIView, viewType: PlayerViewType)
}

// MARK: - 播放器视图服务协议

/// 播放器视图服务协议 - 管理播放器视图层级
@MainActor
public protocol PlayerViewService: PluginService {

    /// 视图容器
    var containerView: UIView { get }

    /// ActionView（交互视图）
    var actionView: PlayerActionView? { get }

    /// 背景色视图
    var backgroundColorView: UIView? { get }

    /// 播控下视图
    var controlUnderlayView: UIView? { get }

    /// 播控视图
    var controlView: UIView? { get }

    /// 播控上视图
    var controlOverlayView: UIView? { get }

    /// 添加视图到指定层级
    /// - Parameters:
    ///   - view: 要添加的视图
    ///   - viewType: 视图类型
    func addSubview(_ view: UIView, viewType: PlayerViewType)

    /// 添加视图到引擎下方
    /// - Parameters:
    ///   - view: 要添加的视图
    ///   - viewType: 视图类型
    func addSubViewBelowEngineView(_ view: UIView, viewType: PlayerViewType)
}

// MARK: - UIView 扩展 - stringTag

private var stringTagKey: UInt8 = 0

public extension UIView {

    /// 视图类型标签（用于标识视图在层级中的类型）
    var playerViewType: PlayerViewType? {
        get {
            guard let tag = ttv_stringTag else { return nil }
            return PlayerViewType(rawValue: tag)
        }
        set {
            ttv_stringTag = newValue?.rawValue
        }
    }
}
