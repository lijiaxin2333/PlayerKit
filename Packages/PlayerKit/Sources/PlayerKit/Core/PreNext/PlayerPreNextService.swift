//
//  PlayerPreNextService.swift
//  playerkit
//
//  预加载下一个服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 预加载下一个视频信息

public struct PlayerPreNextItem: Sendable {
    public let url: URL
    public let title: String?
    public let thumbnailURL: URL?

    public init(url: URL, title: String? = nil, thumbnailURL: URL? = nil) {
        self.url = url
        self.title = title
        self.thumbnailURL = thumbnailURL
    }
}

// MARK: - 预加载下一个服务

@MainActor
public protocol PlayerPreNextService: PluginService {

    /// 下一个播放项
    var nextItem: PlayerPreNextItem? { get set }

    /// 是否正在预加载
    var isPreloading: Bool { get }

    /// 预加载进度
    var preloadProgress: Double { get }

    /// 设置下一个播放项
    func setNextItem(_ item: PlayerPreNextItem?)

    /// 开始预加载
    func startPreload()

    /// 取消预加载
    func cancelPreload()
}

// MARK: - 配置模型

public class PlayerPreNextConfigModel {

    /// 是否自动预加载
    public var autoPreload: Bool = true

    /// 预加载触发时机（当前播放进度达到该值时开始）
    public var preloadThreshold: Double = 0.8

    public init() {}
}
