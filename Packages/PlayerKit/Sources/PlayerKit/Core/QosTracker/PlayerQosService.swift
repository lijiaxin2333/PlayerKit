//
//  PlayerQosService.swift
//  playerkit
//
//  QoS 质量监控服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - QoS 指标

public struct PlayerQosMetrics {
    public var startupTime: TimeInterval = 0           // 起播耗时
    public var totalStalledTime: TimeInterval = 0      // 总卡顿时长
    public var stalledCount: Int = 0                   // 卡顿次数
    public var bufferProgress: Double = 0              // 缓冲进度
    public var bitrate: Int = 0                        // 码率
    public var droppedFrames: Int = 0                  // 丢帧数

    public init() {}
}

// MARK: - QoS 服务

@MainActor
public protocol PlayerQosService: CCLCompService {

    /// 当前 QoS 指标
    var qosMetrics: PlayerQosMetrics { get }

    /// 开始 QoS 监控
    func startQosMonitoring()

    /// 停止 QoS 监控
    func stopQosMonitoring()

    /// 重置 QoS 指标
    func resetQosMetrics()

    /// 上报 QoS 数据
    func reportQosMetrics()
}

// MARK: - 配置模型

public class PlayerQosConfigModel {

    /// 是否启用 QoS 监控
    public var enabled: Bool = true

    /// QoS 上报间隔（秒）
    public var reportInterval: TimeInterval = 10.0

    public init() {}
}
