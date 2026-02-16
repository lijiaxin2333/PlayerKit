//
//  PlayerSpeedService.swift
//  playerkit
//
//  倍速播放服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 倍速选项

/**
 * 倍速选项结构体
 */
public struct PlayerSpeedOption: Equatable {
    /**
     * 播放速率
     */
    public let rate: Float
    /**
     * 显示名称
     */
    public let displayName: String

    /**
     * 初始化
     */
    public init(rate: Float, displayName: String) {
        self.rate = rate
        self.displayName = displayName
    }

    /**
     * 默认倍速（1.0x 正常）
     */
    public static let `default` = PlayerSpeedOption(rate: 1.0, displayName: "正常")
}

// MARK: - 倍速服务

/**
 * 倍速播放服务协议
 */
@MainActor
public protocol PlayerSpeedService: PluginService {

    /**
     * 当前倍速
     */
    var currentSpeed: Float { get set }

    /**
     * 可用的倍速列表
     */
    var availableSpeeds: [PlayerSpeedOption] { get set }

    /**
     * 设置倍速
     */
    func setSpeed(_ speed: Float)

    /**
     * 设置倍速（选项）
     */
    func setSpeed(_ option: PlayerSpeedOption)
}

// MARK: - 配置模型

/**
 * 倍速配置模型
 */
public class PlayerSpeedConfigModel {

    /**
     * 可用的倍速列表
     */
    public var availableSpeeds: [PlayerSpeedOption] = [
        PlayerSpeedOption(rate: 0.5, displayName: "0.5x"),
        PlayerSpeedOption(rate: 0.75, displayName: "0.75x"),
        PlayerSpeedOption(rate: 1.0, displayName: "正常"),
        PlayerSpeedOption(rate: 1.25, displayName: "1.25x"),
        PlayerSpeedOption(rate: 1.5, displayName: "1.5x"),
        PlayerSpeedOption(rate: 2.0, displayName: "2.0x"),
    ]

    /**
     * 默认倍速
     */
    public var defaultSpeed: Float = 1.0

    /**
     * 初始化
     */
    public init() {}
}
