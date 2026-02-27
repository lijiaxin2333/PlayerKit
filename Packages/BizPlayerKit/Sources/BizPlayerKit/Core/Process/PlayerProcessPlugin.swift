//
//  PlayerProcessPlugin.swift
//  playerkit
//
//  播放进度管理组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerProcessPlugin: BasePlugin, PlayerProcessService {

    public typealias ConfigModelType = PlayerProcessConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    public var progressState: PlayerProgressState = .idle
    private var progressHandlers: [String: (Double, TimeInterval) -> Void] = [:]
    private var timeObserver: AnyObject?
    private var scrubbingTargetProgress: Double = 0

    // MARK: - PlayerProcessService

    public var progress: Double {
        let dur = engineService?.duration ?? 0
        return dur > 0 ? (currentTime / dur) : 0
    }

    public var currentTime: TimeInterval {
        return engineService?.currentTime ?? 0
    }

    public var duration: TimeInterval {
        return engineService?.duration ?? 0
    }

    public var bufferProgress: Double {
        return engineService?.bufferProgress ?? 0
    }

    public var isScrubbing: Bool {
        if case .scrubbing = progressState {
            return true
        }
        return false
    }

    // MARK: - Initialization

    public required init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 使用 sticky 事件等待引擎创建，避免 engineService 为 nil
        context.add(self, event: .playerEngineDidCreateSticky, option: .execOnlyOnce) { [weak self] _, _ in
            self?.setupTimeObserver()
        }
    }

    private func setupTimeObserver() {
        guard timeObserver == nil else { return }

        let interval = (configModel as? PlayerProcessConfigModel)?.updateInterval ?? 0.1
        timeObserver = engineService?.addPeriodicTimeObserver(interval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            MainActor.assumeIsolated {
                // scrubbing 期间跳过进度广播，避免进度条跳动
                guard !self.isScrubbing else { return }
                let progress = self.progress
                for handler in self.progressHandlers.values {
                    handler(progress, time)
                }
            }
        }
    }

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)

        if let observer = timeObserver {
            engineService?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - PlayerProcessService

    @discardableResult
    public func observeProgress(_ handler: @escaping (Double, TimeInterval) -> Void) -> String {
        let key = UUID().uuidString
        progressHandlers[key] = handler
        return key
    }

    public func removeProgressObserver(token: String) {
        progressHandlers.removeValue(forKey: token)
    }

    public func removeAllProgressObservers() {
        progressHandlers.removeAll()
    }

    public func beginScrubbing() {
        progressState = .scrubbing
        context?.post(.playerProgressBeginScrubbing, sender: self)
    }

    public func scrubbing(to progress: Double) {
        let clampedProgress = max(0, min(1, progress))
        scrubbingTargetProgress = clampedProgress
        let time = duration * clampedProgress
        context?.post(.playerProgressScrubbing, object: time, sender: self)
    }

    public func endScrubbing() {
        let targetProgress = scrubbingTargetProgress
        seek(to: targetProgress) { [weak self] finished in
            guard let self = self else { return }
            MainActor.assumeIsolated {
                self.progressState = .idle
                self.context?.post(.playerProgressEndScrubbing, sender: self)
            }
        }
    }

    public func seek(to progress: Double, completion: (@Sendable (Bool) -> Void)?) {
        let clampedProgress = max(0, min(1, progress))
        let time = duration * clampedProgress
        engineService?.seek(to: time, completion: completion)
    }
}
