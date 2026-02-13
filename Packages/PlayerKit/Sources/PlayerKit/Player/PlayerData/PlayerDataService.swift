//
//  PlayerDataService.swift
//  playerkit
//
//  播放器数据服务协议
//

import Foundation
import UIKit

// MARK: - 播放器数据模型

/// 播放器数据模型
public struct PlayerDataModel: Sendable {

    /// 视频 URL
    public var videoURL: URL?

    /// 视频 ID
    public var vid: String?

    /// 视频标题
    public var title: String?

    /// 视频作者
    public var author: String?

    /// 视频封面 URL
    public var coverURL: URL?

    /// 视频时长（秒）
    public var duration: TimeInterval = 0

    /// 视频宽度
    public var videoWidth: Int = 0

    /// 视频高度
    public var videoHeight: Int = 0

    /// 是否正在直播
    public var isLive: Bool = false

    /// 自定义数据
    public var customData: [String: AnySendable] = [:]

    public init() {}

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

/// 可发送的任意值包装器
public struct AnySendable: Sendable {
    private let _value: Any

    public init<T: Sendable>(_ value: T) {
        self._value = value
    }

    public var value: Any {
        return _value
    }
}

// MARK: - 播放器数据服务协议

/// 播放器数据服务协议 - 管理播放器数据
@MainActor
public protocol PlayerDataService: CCLCompService {

    /// 当前数据模型
    var dataModel: PlayerDataModel { get }

    /// 数据是否已准备
    var isDataReady: Bool { get }

    /// 更新数据模型
    /// - Parameter model: 新的数据模型
    func updateDataModel(_ model: PlayerDataModel)

    /// 设置视频 URL
    /// - Parameter url: 视频 URL
    func setVideoURL(_ url: URL?)

    /// 设置视频 ID
    /// - Parameter vid: 视频 ID
    func setVid(_ vid: String?)

    /// 获取视频 URL
    /// - Returns: 当前视频 URL
    func getVideoURL() -> URL?

    /// 获取视频尺寸
    /// - Returns: 视频尺寸 (width, height)
    func getVideoSize() -> (width: Int, height: Int)

    /// 清除数据
    func clearData()
}

// MARK: - 数据更新事件

/// 数据模型即将更新事件
public let PlayerDataModelWillUpdateEvent = "PlayerDataModelWillUpdateEvent"

/// 数据模型已更新事件
public let PlayerDataModelDidUpdateEvent = "PlayerDataModelDidUpdateEvent"

/// 数据模型变化事件
public let PlayerDataModelChangedEvent = "PlayerDataModelChangedEvent"
