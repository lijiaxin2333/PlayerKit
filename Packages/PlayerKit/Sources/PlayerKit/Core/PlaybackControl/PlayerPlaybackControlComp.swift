//
//  PlayerPlaybackControlComp.swift
//  playerkit
//
//  播放控制组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerPlaybackControlComp: CCLBaseComp, PlayerPlaybackControlService {

    public typealias ConfigModelType = PlayerPlaybackControlConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?


    // MARK: - PlayerPlaybackControlService

    public var isPlaying: Bool {
        return engineService?.playbackState == .playing
    }

    public var isPaused: Bool {
        return engineService?.playbackState == .paused
    }

    public var canPlay: Bool {
        guard let state = engineService?.playbackState else { return false }
        return state == .paused || state == .stopped || state == .seeking
    }

    public var canPause: Bool {
        return engineService?.playbackState == .playing
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - Methods

    public func play() {
        engineService?.play()
    }

    public func pause() {
        engineService?.pause()
    }

    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    public func stop() {
        engineService?.stop()
    }

    public func replay() {
        engineService?.seek(to: 0) { [weak self] finished in
            if finished {
                self?.play()
            }
        }
    }
}
