//
//  PlayerReplayPlugin.swift
//  playerkit
//
//  重播组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerReplayPlugin: BasePlugin, PlayerReplayService {

    public typealias ConfigModelType = PlayerReplayConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _replayCount: Int = 0

    // MARK: - PlayerReplayService

    public var canReplay: Bool {
        guard let config = configModel as? PlayerReplayConfigModel else { return true }
        return config.maxReplayCount == 0 || _replayCount < config.maxReplayCount
    }

    public var replayCount: Int {
        return _replayCount
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 监听播放完成事件
        self.context?.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            guard let self = self else { return }
            // 可以在这里处理自动重播逻辑
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerReplayService

    public func replay() {
        guard canReplay else { return }

        let config = configModel as? PlayerReplayConfigModel
        let startTime = config?.replayFromStart == true ? 0.0 : nil
        replay(from: startTime ?? 0.0)
    }

    public func replay(from time: TimeInterval) {
        guard canReplay else { return }

        _replayCount += 1

        engineService?.seek(to: time) { [weak self] finished in
            if finished {
                self?.engineService?.play()
            }
        }
    }
}
