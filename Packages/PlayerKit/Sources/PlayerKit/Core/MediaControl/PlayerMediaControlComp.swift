//
//  PlayerMediaControlComp.swift
//  playerkit
//
//  媒体控制组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerMediaControlComp: CCLBaseComp, PlayerMediaControlService {

    public typealias ConfigModelType = PlayerMediaControlConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _volume: Float = 1.0
    private var _brightness: Float = 0.5
    private var _isMuted: Bool = false
    private var volumeBeforeMute: Float = 1.0

    // MARK: - PlayerMediaControlService

    public var volume: Float {
        get { _volume }
        set {
            _volume = max(0, min(1, newValue))
            engineService?.volume = _isMuted ? 0 : _volume
            context?.post(.playerVolumeDidChange, object: _volume, sender: self)
        }
    }

    public var brightness: Float {
        get { _brightness }
        set {
            _brightness = max(0, min(1, newValue))
            UIScreen.main.brightness = CGFloat(_brightness)
            context?.post(.playerBrightnessDidChange, object: _brightness, sender: self)
        }
    }

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

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        // 同步当前系统亮度
        _brightness = Float(UIScreen.main.brightness)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerMediaControlConfigModel else { return }

        volume = config.initialVolume
    }

    // MARK: - Methods

    public func setVolume(_ volume: Float, animated: Bool) {
        self.volume = volume
    }

    public func setBrightness(_ brightness: Float, animated: Bool) {
        self.brightness = brightness
    }

    public func toggleMute() {
        isMuted.toggle()
    }

    public func increaseVolume(delta: Float) {
        volume = min(1, volume + delta)
    }

    public func decreaseVolume(delta: Float) {
        volume = max(0, volume - delta)
    }
}
