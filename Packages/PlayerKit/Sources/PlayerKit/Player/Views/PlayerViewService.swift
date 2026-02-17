//
//  PlayerViewService.swift
//  playerkit
//

import Foundation
import UIKit

/** 播放器 ActionView 协议，定义视图添加能力 */
@MainActor
public protocol PlayerActionViewProtocol: AnyObject {

    /** 添加视图到指定层级 */
    func addSubview(_ view: UIView, viewType: PlayerViewType)
}

/** 播放器视图服务协议，管理播放器视图层级结构 */
@MainActor
public protocol PlayerViewService: PluginService {

    /** 视图容器 */
    var containerView: UIView { get }

    /** 交互视图（ActionView） */
    var actionView: PlayerActionView? { get }

    /** 背景色视图 */
    var backgroundColorView: UIView? { get }

    /** 播控下层视图 */
    var controlUnderlayView: UIView? { get }

    /** 播控视图 */
    var controlView: UIView? { get }

    /** 播控上层视图 */
    var controlOverlayView: UIView? { get }

    /** 添加视图到指定层级 */
    func addSubview(_ view: UIView, viewType: PlayerViewType)

    /** 添加视图到引擎视图下方 */
    func addSubViewBelowEngineView(_ view: UIView, viewType: PlayerViewType)
}

/** UIView 字符串标签关联键 */
private nonisolated(unsafe) var stringTagKey: UInt8 = 0

public extension UIView {

    /** 视图类型标签，用于标识视图在层级中的类型 */
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
