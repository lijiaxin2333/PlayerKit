//
//  PlayerViewService.swift
//  playerkit
//
//  播放器视图服务协议
//

import Foundation
import UIKit

/// 播放器视图服务协议，提供播放器渲染视图
@MainActor
public protocol PlayerViewService: PluginService {

    /// 播放器渲染视图
    var playerView: UIView? { get }
}
