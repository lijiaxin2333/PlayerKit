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

public struct PlayerSpeedOption: Equatable {
    public let rate: Float
    public let displayName: String

    public init(rate: Float, displayName: String) {
        self.rate = rate
        self.displayName = displayName
    }

    public static let `default` = PlayerSpeedOption(rate: 1.0, displayName: "正常")
}

// MARK: - 倍速服务

@MainActor
public protocol PlayerSpeedService: CCLCompService {

    /// 当前倍速
    var currentSpeed: Float { get set }

    /// 可用的倍速列表
    var availableSpeeds: [PlayerSpeedOption] { get set }

    /// 设置倍速
    func setSpeed(_ speed: Float)

    /// 设置倍速（选项）
    func setSpeed(_ option: PlayerSpeedOption)
}

// MARK: - 配置模型

public class PlayerSpeedConfigModel {

    /// 可用的倍速列表
    public var availableSpeeds: [PlayerSpeedOption] = [
        PlayerSpeedOption(rate: 0.5, displayName: "0.5x"),
        PlayerSpeedOption(rate: 0.75, displayName: "0.75x"),
        PlayerSpeedOption(rate: 1.0, displayName: "正常"),
        PlayerSpeedOption(rate: 1.25, displayName: "1.25x"),
        PlayerSpeedOption(rate: 1.5, displayName: "1.5x"),
        PlayerSpeedOption(rate: 2.0, displayName: "2.0x"),
    ]

    /// 默认倍速
    public var defaultSpeed: Float = 1.0

    public init() {}
}
