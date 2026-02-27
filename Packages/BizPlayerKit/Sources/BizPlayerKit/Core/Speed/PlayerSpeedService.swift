//
//  PlayerSpeedService.swift
//  playerkit
//
//  倍速播放服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Types

public struct PlayerSpeedOption: Equatable, Sendable {
    public let rate: Float
    public let displayName: String

    public init(rate: Float, displayName: String) {
        self.rate = rate
        self.displayName = displayName
    }

    public static let `default` = PlayerSpeedOption(rate: 1.0, displayName: "正常")
}

// MARK: - Speed Events

public extension Event {
    /// 倍速改变
    static let playerSpeedDidChange: Event = "PlayerSpeedDidChange"
    /// 倍速（粘性事件）
    static let playerRateDidChangeSticky: Event = "PlayerRateDidChangeSticky"
}

// MARK: - PlayerSpeedService Protocol

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
