//
//  PlayerQosPlugin.swift
//  playerkit
//
//  QoS 质量监控组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerQosPlugin: BasePlugin, PlayerQosService {

    public typealias ConfigModelType = PlayerQosConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _qosMetrics: PlayerQosMetrics = PlayerQosMetrics()
    private var isMonitoring: Bool = false
    private var reportTimer: Timer?
    private var lastStalledStartTime: Date?
    private var playbackStartTime: Date?

    // MARK: - PlayerQosService

    public var qosMetrics: PlayerQosMetrics {
        get { _qosMetrics }
        set { _qosMetrics = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 监听播放开始
        self.context?.add(self, event: .playerPlaybackStateChanged) { [weak self] state, _ in
            guard let self = self else { return }
            if case .playing = state as? PlayerPlaybackState {
                if self.playbackStartTime == nil {
                    self.playbackStartTime = Date()
                }
            }
        }

        // 监听卡顿事件
        self.context?.add(self, event: .playerPlayingStalledBegin) { [weak self] _, _ in
            self?.lastStalledStartTime = Date()
            print("[PlayerQosPlugin] ⚠️ 开始卡顿")
        }

        self.context?.add(self, event: .playerPlayingStalledEnd) { [weak self] object, _ in
            guard let self = self, let startTime = self.lastStalledStartTime else { return }
            let duration = Date().timeIntervalSince(startTime)
            self._qosMetrics.totalStalledTime += duration
            self._qosMetrics.stalledCount += 1
            self.lastStalledStartTime = nil
            print("[PlayerQosPlugin] ✓ 结束卡顿, 耗时: \(String(format: "%.2f", duration))秒")
        }

        // 监听首帧
        self.context?.add(self, event: .playerReadyForDisplaySticky) { [weak self] _, _ in
            guard let self = self, let startTime = self.playbackStartTime else { return }
            self._qosMetrics.startupTime = Date().timeIntervalSince(startTime)
            print("[PlayerQosPlugin] 🎬 首帧耗时: \(String(format: "%.2f", self._qosMetrics.startupTime))秒")
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerQosConfigModel else { return }

        if config.enabled {
            startQosMonitoring()
        }
    }

    // MARK: - PlayerQosService

    public func startQosMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true

        // 启动定时上报
        let config = configModel as? PlayerQosConfigModel
        let interval = config?.reportInterval ?? 10.0
        reportTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.reportQosMetrics()
        }

        print("[PlayerQosPlugin] 📊 开始 QoS 监控, 上报间隔: \(interval)秒")
    }

    public func stopQosMonitoring() {
        isMonitoring = false
        reportTimer?.invalidate()
        reportTimer = nil
        print("[PlayerQosPlugin] 📊 停止 QoS 监控")
    }

    public func resetQosMetrics() {
        _qosMetrics = PlayerQosMetrics()
        lastStalledStartTime = nil
        playbackStartTime = nil
        print("[PlayerQosPlugin] 🔄 重置 QoS 指标")
    }

    public func reportQosMetrics() {
        // 更新实时指标
        _qosMetrics.bufferProgress = engineService?.bufferProgress ?? 0

        print("[PlayerQosPlugin] 📊 QoS 指标上报")
        print("  ├─ 起播耗时: \(String(format: "%.2f", _qosMetrics.startupTime))秒")
        print("  ├─ 总卡顿时长: \(String(format: "%.2f", _qosMetrics.totalStalledTime))秒")
        print("  ├─ 卡顿次数: \(_qosMetrics.stalledCount)")
        print("  ├─ 缓冲进度: \(String(format: "%.1f", _qosMetrics.bufferProgress * 100))%")
        print("  └─ 码率: \(_qosMetrics.bitrate)")
    }
}
