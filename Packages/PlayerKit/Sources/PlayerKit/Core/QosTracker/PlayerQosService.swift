//
//  PlayerQosService.swift
//  playerkit
//
//  QoS 质量监控服务协议
//

import Foundation
import AVFoundation
import UIKit

/**
 * QoS 指标结构体，包含起播、卡顿、缓冲等数据
 */
public struct PlayerQosMetrics {
    /** 起播耗时（秒） */
    public var startupTime: TimeInterval = 0
    /** 总卡顿时长（秒） */
    public var totalStalledTime: TimeInterval = 0
    /** 卡顿次数 */
    public var stalledCount: Int = 0
    /** 缓冲进度 0-1 */
    public var bufferProgress: Double = 0
    /** 当前码率 */
    public var bitrate: Int = 0
    /** 丢帧数 */
    public var droppedFrames: Int = 0

    public init() {}
}

@MainActor
/**
 * QoS 质量监控服务协议，提供 QoS 监控启停、指标重置及上报能力
 */
public protocol PlayerQosService: PluginService {

    /** 当前 QoS 指标 */
    var qosMetrics: PlayerQosMetrics { get }

    /**
     * 开始 QoS 监控
     */
    func startQosMonitoring()

    /**
     * 停止 QoS 监控
     */
    func stopQosMonitoring()

    /**
     * 重置 QoS 指标
     */
    func resetQosMetrics()

    /**
     * 上报 QoS 数据
     */
    func reportQosMetrics()
}

/**
 * QoS 配置模型
 */
public class PlayerQosConfigModel {

    /** 是否启用 QoS 监控 */
    public var enabled: Bool = true

    /** QoS 上报间隔（秒） */
    public var reportInterval: TimeInterval = 10.0

    public init() {}
}
