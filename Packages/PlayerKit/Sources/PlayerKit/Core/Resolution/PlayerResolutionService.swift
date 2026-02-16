import Foundation
import AVFoundation
import UIKit

/**
 * 分辨率信息结构体
 */
public struct PlayerResolutionInfo: Equatable {
    /** 宽度（像素） */
    public let width: Int
    /** 高度（像素） */
    public let height: Int
    /** 码率 */
    public let bitrate: Int
    /** 显示名称（如 1080P） */
    public let displayName: String

    /**
     * 初始化
     */
    public init(width: Int, height: Int, bitrate: Int, displayName: String) {
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.displayName = displayName
    }

    /** 自动选择分辨率的占位信息 */
    public static let auto = PlayerResolutionInfo(
        width: 0, height: 0, bitrate: 0,
        displayName: "自动"
    )

    /** 是否为自动模式 */
    public var isAuto: Bool {
        return width == 0 && height == 0
    }
}

/**
 * 分辨率服务协议
 */
@MainActor
public protocol PlayerResolutionService: PluginService {

    /** 当前分辨率 */
    var currentResolution: PlayerResolutionInfo? { get }

    /** 可用的分辨率列表 */
    var availableResolutions: [PlayerResolutionInfo] { get }

    /**
     * 设置分辨率
     */
    func setResolution(_ resolution: PlayerResolutionInfo)

    /**
     * 获取分辨率列表
     */
    func fetchResolutions(completion: @escaping ([PlayerResolutionInfo]) -> Void)
}

/**
 * 分辨率配置模型
 */
public class PlayerResolutionConfigModel {

    /** 默认分辨率 */
    public var defaultResolution: PlayerResolutionInfo = .auto

    /** 是否自动选择最佳分辨率 */
    public var autoSelectBest: Bool = true

    /**
     * 初始化
     */
    public init() {}
}
