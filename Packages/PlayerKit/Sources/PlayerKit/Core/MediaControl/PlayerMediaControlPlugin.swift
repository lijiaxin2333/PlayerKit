import Foundation
import AVFoundation
import UIKit

/**
 * 媒体控制插件，负责音量和亮度的调节
 */
@MainActor
public final class PlayerMediaControlPlugin: BasePlugin, PlayerMediaControlService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerMediaControlConfigModel

    /** 引擎核心服务 */
    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    /** 当前音量值 */
    private var _volume: Float = 1.0
    /** 当前亮度值 */
    private var _brightness: Float = 0.5
    /** 是否静音 */
    private var _isMuted: Bool = false
    /** 静音前的音量值 */
    private var volumeBeforeMute: Float = 1.0

    /**
     * 当前音量（0-1）
     */
    public var volume: Float {
        get { _volume }
        set {
            _volume = max(0, min(1, newValue))
            engineService?.volume = _isMuted ? 0 : _volume
            context?.post(.playerVolumeDidChange, object: _volume, sender: self)
        }
    }

    /**
     * 当前亮度（0-1）
     */
    public var brightness: Float {
        get { _brightness }
        set {
            _brightness = max(0, min(1, newValue))
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
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成，同步当前系统亮度
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        _brightness = Float(UIScreen.main.brightness)
    }

    /**
     * 配置插件，应用初始音量
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerMediaControlConfigModel else { return }

        volume = config.initialVolume
    }

    /**
     * 设置音量
     */
    public func setVolume(_ volume: Float, animated: Bool) {
        self.volume = volume
    }

    /**
     * 设置亮度
     */
    public func setBrightness(_ brightness: Float, animated: Bool) {
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
