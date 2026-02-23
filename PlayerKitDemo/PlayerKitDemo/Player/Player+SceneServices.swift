//
//  Player+SceneServices.swift
//  PlayerKitDemo
//
//  Player 扩展 - 场景层服务便捷访问
//

import Foundation
import PlayerKit

@MainActor
extension Player {

    /// 手势服务，管理手势交互
    public var gestureService: PlayerGestureService? {
        context.resolveService(PlayerGestureService.self)
    }


    /// 缩放服务，管理视频缩放
    public var zoomService: PlayerZoomService? {
        context.resolveService(PlayerZoomService.self)
    }

    /// 播控视图服务，管理播控视图显示
    public var controlViewService: PlayerControlViewService? {
        context.resolveService(PlayerControlViewService.self)
    }

    /// 全屏服务，管理全屏切换
    public var fullScreenService: PlayerFullScreenService? {
        context.resolveService(PlayerFullScreenService.self)
    }

    /// 遮罩服务，管理播放器遮罩
    public var coverMaskService: PlayerCoverMaskService? {
        context.resolveService(PlayerCoverMaskService.self)
    }

    /// Toast 服务，管理 Toast 提示
    public var toastService: PlayerToastService? {
        context.resolveService(PlayerToastService.self)
    }

    /// 完成视图服务，管理播放结束视图
    public var finishViewService: PlayerFinishViewService? {
        context.resolveService(PlayerFinishViewService.self)
    }

    /// 面板服务，管理面板显示
    public var panelService: PlayerPanelService? {
        context.resolveService(PlayerPanelService.self)
    }

    /// 速度面板服务，管理倍速面板
    public var speedPanelService: PlayerSpeedPanelService? {
        context.resolveService(PlayerSpeedPanelService.self)
    }

    /// 调试服务，提供调试功能
    public var debugService: PlayerDebugService? {
        context.resolveService(PlayerDebugService.self)
    }

    /// 提示管理服务，管理播放器提示
    public var tipManagerService: PlayerTipManagerService? {
        context.resolveService(PlayerTipManagerService.self)
    }
}
