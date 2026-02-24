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

    @PlayerPlugin public var gestureService: PlayerGestureService?
    @PlayerPlugin public var zoomService: PlayerZoomService?
    @PlayerPlugin public var controlViewService: PlayerControlViewService?
    @PlayerPlugin public var fullScreenService: PlayerFullScreenService?
    @PlayerPlugin public var coverMaskService: PlayerCoverMaskService?
    @PlayerPlugin public var toastService: PlayerToastService?
    @PlayerPlugin public var finishViewService: PlayerFinishViewService?
    @PlayerPlugin public var panelService: PlayerPanelService?
    @PlayerPlugin public var speedPanelService: PlayerSpeedPanelService?
    @PlayerPlugin public var debugService: PlayerDebugService?
    @PlayerPlugin public var tipManagerService: PlayerTipManagerService?
}
