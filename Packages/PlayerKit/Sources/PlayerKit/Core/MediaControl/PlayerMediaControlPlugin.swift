import Foundation
import AVFoundation
import UIKit

/**
 * 媒体控制插件，负责音量和亮度的调节
 * - 作为音量/亮度的唯一管理入口，引擎层不再广播音量事件
 */
@MainActor
public final class PlayerMediaControlPlugin: BasePlugin, PlayerMediaControlService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerMediaControlConfigModel

    /** 引擎核心服务 */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /** 配置 */
    private var config: PlayerMediaControlConfigModel?

    /** 当前音量值 */
    private var _volume: Float = 1.0
    /** 当前亮度值 */
    private var _brightness: Float = 0.5
    /** 是否静音 */
    private var _isMuted: Bool = false
    /** 静音前的音量值 */
    private var volumeBeforeMute: Float = 1.0
    /** 进入播放器时的原始亮度 */
    private var originalBrightness: Float = 0.5

    /**
     * 当前音量（0-1）
     */
    public var volume: Float {
        get { _volume }
        set {
            let clamped = max(0, min(1, newValue))
            guard _volume != clamped else { return }
            _volume = clamped

            // 静音时只更新逻辑音量，不设置引擎
            if !_isMuted {
                engineService?.volume = _volume
            }
            context?.post(.playerVolumeDidChange, object: _volume, sender: self)
        }
    }

    /**
     * 当前亮度（0-1）
     */
    public var brightness: Float {
        get { _brightness }
        set {
            let clamped = max(0, min(1, newValue))
            guard _brightness != clamped else { return }
            _brightness = clamped
            UIScreen.main.brightness = CGFloat(_brightness)
            context?.post(.playerBrightnessDidChange, object: _brightness, sender: self)
        }
    }

    /**
     * 是否静音
     */
    public var isMuted: Bool {
        get { _isMuted }
        set {
            guard _isMuted != newValue else { return }
            _isMuted = newValue
            if _isMuted {
                volumeBeforeMute = _volume
                engineService?.volume = 0
            } else {
                engineService?.volume = _volume
            }
        }
    }

    /**
     * 初始化
     */
    public required init() {
        super.init()
    }

    /**
     * 插件加载完成，保存并同步当前系统亮度
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 保存原始亮度，用于退出时恢复
        originalBrightness = Float(UIScreen.main.brightness)
        _brightness = originalBrightness
    }

    /**
     * 插件卸载，恢复系统亮度
     */
    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)

        // 恢复原始亮度
        if config?.restoreBrightnessOnUnload ?? true {
            UIScreen.main.brightness = CGFloat(originalBrightness)
        }
    }

    /**
     * 配置插件，应用初始音量
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerMediaControlConfigModel else { return }
        self.config = config

        volume = config.initialVolume
    }

    /**
     * 设置音量
     */
    public func setVolume(_ volume: Float, animated: Bool) {
        // TODO: 支持 animated，使用 CADisplayLink 做平滑过渡
        self.volume = volume
    }

    /**
     * 设置亮度
     */
    public func setBrightness(_ brightness: Float, animated: Bool) {
        // TODO: 支持 animated，使用 UIView.animate 逐帧设置
        self.brightness = brightness
    }

    /**
     * 切换静音状态
     */
    public func toggleMute() {
        isMuted.toggle()
    }

    /**
     * 增加音量
     */
    public func increaseVolume(delta: Float) {
        volume = min(1, volume + delta)
    }

    /**
     * 减少音量
     */
    public func decreaseVolume(delta: Float) {
        volume = max(0, volume - delta)
    }
}
