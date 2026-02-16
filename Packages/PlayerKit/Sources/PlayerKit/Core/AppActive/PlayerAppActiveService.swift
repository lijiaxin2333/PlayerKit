//
//  PlayerAppActiveService.swift
//  playerkit
//
//  前后台处理服务协议
//

import Foundation
import AVFoundation
import UIKit

// MARK: - App 状态

public enum PlayerAppState {
    case didBecomeActive
    case didResignActive
    case willEnterForeground
    case didEnterBackground
}

// MARK: - App 前后台服务

@MainActor
public protocol PlayerAppActiveService: PluginService {

    /// 当前 App 状态
    var appState: PlayerAppState { get }

    /// App 是否在前台
    var isAppActive: Bool { get }

    /// 处理 App 进入前台
    func handleAppBecomeActive()

    /// 处理 App 进入后台
    func handleAppResignActive()
}

// MARK: - 配置模型

public class PlayerAppActiveConfigModel {

    /// 进入后台时是否暂停播放
    public var pauseWhenResignActive: Bool = true

    /// 进入前台时是否恢复播放
    public var resumeWhenBecomeActive: Bool = false

    public init() {}
}
