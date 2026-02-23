import Foundation
import AVFoundation
import UIKit

// MARK: - Types

public enum PlayerMediaControlType {
    case volume
    case brightness
}

// MARK: - MediaControl Events

public extension Event {
    /// 音量改变
    static let playerVolumeDidChange: Event = "PlayerVolumeDidChange"
    /// 亮度改变
    static let playerBrightnessDidChange: Event = "PlayerBrightnessDidChange"
}

// MARK: - PlayerMediaControlService Protocol
@MainActor
public protocol PlayerMediaControlService: PluginService {

    /** 当前音量（0-1） */
    var volume: Float { get set }

    /** 当前亮度（0-1） */
    var brightness: Float { get set }

    /** 是否静音 */
    var isMuted: Bool { get set }

    /**
     * 设置音量
     */
    func setVolume(_ volume: Float, animated: Bool)

    /**
     * 设置亮度
     */
    func setBrightness(_ brightness: Float, animated: Bool)

    /**
     * 切换静音
     */
    func toggleMute()

    /**
     * 增加音量
     */
    func increaseVolume(delta: Float)

    /**
     * 减少音量
     */
    func decreaseVolume(delta: Float)
}

/**
 * 媒体控制配置模型
 */
public class PlayerMediaControlConfigModel {

    /** 初始音量 */
    public var initialVolume: Float = 1.0

    /** 是否允许手势调节音量 */
    public var allowVolumeGesture: Bool = true

    /** 是否允许手势调节亮度 */
    public var allowBrightnessGesture: Bool = true

    /** 退出时是否恢复亮度 */
    public var restoreBrightnessOnUnload: Bool = true

    /**
     * 初始化
     */
    public init() {}
}
