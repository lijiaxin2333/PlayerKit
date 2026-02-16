//
//  PlayerAppActiveService.swift
//  playerkit
//
//  前后台处理服务协议
//

import Foundation
import AVFoundation
import UIKit

/**
 * 应用状态枚举
 */
public enum PlayerAppState {
    case didBecomeActive
    case didResignActive
    case willEnterForeground
    case didEnterBackground
}

/**
 * 应用前后台服务协议
 */
@MainActor
public protocol PlayerAppActiveService: PluginService {

    /**
     * 当前 App 状态
     */
    var appState: PlayerAppState { get }

    /**
     * App 是否在前台
     */
    var isAppActive: Bool { get }

    /**
     * 处理 App 进入前台
     */
    func handleAppBecomeActive()

    /**
     * 处理 App 进入后台
     */
    func handleAppResignActive()
}

/**
 * 应用前后台配置模型
 */
public class PlayerAppActiveConfigModel {

    /**
     * 进入后台时是否暂停播放
     */
    public var pauseWhenResignActive: Bool = true

    /**
     * 进入前台时是否恢复播放
     */
    public var resumeWhenBecomeActive: Bool = false

    /**
     * 初始化配置
     */
    public init() {}
}
