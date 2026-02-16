//
//  PlayerMediaControlService.swift
//  playerkit
//
//  媒体控制服务（音量/亮度）
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 媒体控制类型

public enum PlayerMediaControlType {
    case volume
    case brightness
}

// MARK: - 媒体控制服务

@MainActor
public protocol PlayerMediaControlService: PluginService {

    /// 当前音量（0-1）
    var volume: Float { get set }

    /// 当前亮度（0-1）
    var brightness: Float { get set }

    /// 是否静音
    var isMuted: Bool { get set }

    /// 设置音量
    func setVolume(_ volume: Float, animated: Bool)

    /// 设置亮度
    func setBrightness(_ brightness: Float, animated: Bool)

    /// 切换静音
    func toggleMute()

    /// 增加音量
    func increaseVolume(delta: Float)

    /// 减少音量
    func decreaseVolume(delta: Float)
}

// MARK: - 配置模型

public class PlayerMediaControlConfigModel {

    /// 初始音量
    public var initialVolume: Float = 1.0

    /// 是否允许手势调节音量
    public var allowVolumeGesture: Bool = true

    /// 是否允许手势调节亮度
    public var allowBrightnessGesture: Bool = true

    public init() {}
}
