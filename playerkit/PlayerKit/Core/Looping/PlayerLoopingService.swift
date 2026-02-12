//
//  PlayerLoopingService.swift
//  playerkit
//
//  循环播放服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 循环模式

public enum PlayerLoopingMode {
    case none       // 不循环
    case one        // 单曲循环
    case all        // 列表循环
}

// MARK: - 循环播放服务

@MainActor
public protocol PlayerLoopingService: CCLCompService {

    /// 循环模式
    var loopingMode: PlayerLoopingMode { get set }

    /// 是否循环
    var isLooping: Bool { get }

    /// 切换循环模式
    func toggleLooping()

    /// 设置循环模式
    func setLoopingMode(_ mode: PlayerLoopingMode)
}

// MARK: - 配置模型

public class PlayerLoopingConfigModel {

    /// 默认循环模式
    public var defaultMode: PlayerLoopingMode = .none

    public init() {}
}
