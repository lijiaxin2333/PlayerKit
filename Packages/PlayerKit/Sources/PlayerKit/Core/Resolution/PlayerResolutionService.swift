//
//  PlayerResolutionService.swift
//  playerkit
//
//  分辨率/清晰度服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 分辨率信息

public struct PlayerResolutionInfo: Equatable {
    public let width: Int
    public let height: Int
    public let bitrate: Int
    public let displayName: String

    public init(width: Int, height: Int, bitrate: Int, displayName: String) {
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.displayName = displayName
    }

    public static let auto = PlayerResolutionInfo(
        width: 0, height: 0, bitrate: 0,
        displayName: "自动"
    )

    public var isAuto: Bool {
        return width == 0 && height == 0
    }
}

// MARK: - 分辨率服务

@MainActor
public protocol PlayerResolutionService: PluginService {

    /// 当前分辨率
    var currentResolution: PlayerResolutionInfo? { get }

    /// 可用的分辨率列表
    var availableResolutions: [PlayerResolutionInfo] { get }

    /// 设置分辨率
    func setResolution(_ resolution: PlayerResolutionInfo)

    /// 获取分辨率列表
    func fetchResolutions(completion: @escaping ([PlayerResolutionInfo]) -> Void)
}

// MARK: - 配置模型

public class PlayerResolutionConfigModel {

    /// 默认分辨率
    public var defaultResolution: PlayerResolutionInfo = .auto

    /// 是否自动选择最佳分辨率
    public var autoSelectBest: Bool = true

    public init() {}
}
