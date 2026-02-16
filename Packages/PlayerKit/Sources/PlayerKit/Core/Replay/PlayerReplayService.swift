import Foundation
import AVFoundation
import UIKit

/**
 * 重播服务协议
 */
@MainActor
public protocol PlayerReplayService: PluginService {

    /** 是否可以重播 */
    var canReplay: Bool { get }

    /** 已重播次数 */
    var replayCount: Int { get }

    /**
     * 重播
     */
    func replay()

    /**
     * 从指定时间点开始重播
     */
    func replay(from time: TimeInterval)
}

/**
 * 重播配置模型
 */
public class PlayerReplayConfigModel {

    /** 最大重播次数（0 表示无限制） */
    public var maxReplayCount: Int = 0

    /** 重播是否从头开始 */
    public var replayFromStart: Bool = true

    /**
     * 初始化
     */
    public init() {}
}
