//
//  PlayerReplayService.swift
//  playerkit
//
//  重播服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 重播服务

@MainActor
public protocol PlayerReplayService: PluginService {

    /// 是否可以重播
    var canReplay: Bool { get }

    /// 重播次数
    var replayCount: Int { get }

    /// 重播
    func replay()

    /// 重播并指定起始时间
    func replay(from time: TimeInterval)
}

// MARK: - 配置模型

public class PlayerReplayConfigModel {

    /// 最大重播次数（0 表示无限制）
    public var maxReplayCount: Int = 0

    /// 重播是否从头开始
    public var replayFromStart: Bool = true

    public init() {}
}
