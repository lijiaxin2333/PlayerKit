//
//  PlayerDataService.swift
//  playerkit
//

import Foundation
import UIKit

/** 播放器数据模型，存储视频相关的所有元数据 */
public struct PlayerDataModel: Sendable {

    /** 视频 URL */
    public var videoURL: URL?

    /** 视频 ID */
    public var vid: String?

    /** 视频标题 */
    public var title: String?

    /** 视频作者 */
    public var author: String?

    /** 视频封面 URL */
    public var coverURL: URL?

    /** 视频时长（秒） */
    public var duration: TimeInterval = 0

    /** 视频宽度（像素） */
    public var videoWidth: Int = 0

    /** 视频高度（像素） */
    public var videoHeight: Int = 0

    /** 是否正在直播 */
    public var isLive: Bool = false

    /** 自定义数据字典 */
    public var customData: [String: AnySendable] = [:]

    /** 初始化空数据模型 */
    public init() {}

    /** 初始化数据模型，可指定各项属性 */
    public init(videoURL: URL? = nil,
                vid: String? = nil,
                title: String? = nil,
                author: String? = nil,
                coverURL: URL? = nil,
                duration: TimeInterval = 0,
                videoWidth: Int = 0,
                videoHeight: Int = 0,
                isLive: Bool = false) {
        self.videoURL = videoURL
        self.vid = vid
        self.title = title
        self.author = author
        self.coverURL = coverURL
        self.duration = duration
        self.videoWidth = videoWidth
        self.videoHeight = videoHeight
        self.isLive = isLive
    }
}

/** 可发送的任意值包装器，用于在 Sendable 上下文中传递任意类型 */
public struct AnySendable: @unchecked Sendable {
    /** 内部存储的值 */
    private let _value: Any

    /** 初始化包装器 */
    public init<T: Sendable>(_ value: T) {
        self._value = value
    }

    /** 获取包装的值 */
    public var value: Any {
        return _value
    }
}

/** 播放器数据服务协议，管理播放器数据的读写和变更通知 */
@MainActor
public protocol PlayerDataService: PluginService {

    /** 当前数据模型 */
    var dataModel: PlayerDataModel { get }

    /** 数据是否已准备就绪 */
    var isDataReady: Bool { get }

    func updateDataModel(_ model: PlayerDataModel)

    func clearData()

    func updatePlayerInfo()
}

// MARK: - Data Events

public extension Event {
    /// 数据模型即将更新
    static let playerDataModelWillUpdate: Event = "PlayerDataModelWillUpdateEvent"
    /// 数据模型已更新
    static let playerDataModelDidUpdate: Event = "PlayerDataModelDidUpdateEvent"
    /// 数据模型已更新（粘性事件）
    static let playerDataModelDidUpdateSticky: Event = "PlayerDataModelDidUpdateSticky"
    /// 数据模型变化
    static let playerDataModelChanged: Event = "PlayerDataModelChangedEvent"
}
