//
//  PlayerZoomService.swift
//  PlayerKit
//
//  自由缩放服务协议
//

import Foundation
import UIKit
import BizPlayerKit

// MARK: - Zoom Types

/// 自由缩放模式
public enum PlayerZoomMode: Int, Sendable {
    /// 原始大小，不缩放
    case noZoom = 0
    /// 智能满屏（AspectFill）
    case aspectFill
    /// 自定义缩放
    case custom
}

/// 缩放状态信息
public struct PlayerZoomState: Sendable {
    /// 当前缩放模式
    public let mode: PlayerZoomMode
    /// 缩放比例（1.0 = 原始大小）
    public let scale: CGFloat
    /// 是否来自手势操作
    public let fromGesture: Bool

    public init(mode: PlayerZoomMode, scale: CGFloat, fromGesture: Bool = false) {
        self.mode = mode
        self.scale = scale
        self.fromGesture = fromGesture
    }
}

// MARK: - Zoom Events

public extension Event {
    /// 自由缩放状态变化
    static let playerZoomStateDidChanged: Event = "PlayerZoomStateDidChanged"
    /// 智能满屏开关变化
    static let playerAspectFillDidChanged: Event = "PlayerAspectFillDidChanged"
}

// MARK: - Zoom Service Protocol

@MainActor
public protocol PlayerZoomService: PluginService {

    // MARK: - 状态

    /// 是否禁用智能满屏
    var disableZoom: Bool { get }

    /// 是否禁用自由缩放手势
    var disableFreeZoomGesture: Bool { get }

    /// 当前缩放模式
    var zoomMode: PlayerZoomMode { get }

    /// 当前缩放比例
    var scale: CGFloat { get }

    /// 是否处于智能满屏状态
    var isInAspectFill: Bool { get }

    /// 是否开启了智能满屏开关
    var isTurnOnAspectFill: Bool { get }

    // MARK: - 能力查询

    /// 是否支持智能满屏
    func canZoomToAspectFill() -> Bool

    // MARK: - 控制

    /// 开启/关闭智能满屏
    func setAspectFillEnable(_ enable: Bool, animated: Bool)

    /// 设置缩放比例
    func setScale(_ scale: CGFloat)

    /// 设置播放器复用时是否继承智能满屏状态
    func setAspectFillStateInherit(_ enable: Bool)

    /// 设置全屏时智能满屏是否限制最大移动距离不超出屏幕
    func setFullScreenStickBottomSlide(_ fullScreenStickBottomSlide: Bool)
}

// MARK: - Zoom Config Model

/// 自由缩放配置模型
public class PlayerZoomConfigModel {

    /// 是否禁用智能满屏
    public var disableZoom: Bool = false

    /// 是否禁用自由缩放手势
    public var disableFreeZoomGesture: Bool = false

    /// 最小缩放比例
    public var minimumScale: CGFloat = 0.5

    /// 最大缩放比例
    public var maximumScale: CGFloat = 3.0

    /// 是否支持旋转
    public var rotationEnabled: Bool = true

    public init() {}
}
