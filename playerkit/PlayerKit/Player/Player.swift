//
//  Player.swift
//  playerkit
//
//  基于 CCL 架构的主播放器类（简化版）
//

import Foundation
import UIKit
import AVFoundation

@MainActor
final class PlayerRegProvider: CCLRegisterProvider {
    func registerComps(with registerSet: CCLCompRegisterSet) {
        registerSet.addEntry(compClass: PlayerDataComp.self, serviceType: PlayerDataService.self)
        registerSet.addEntry(compClass: PlayerEngineCoreComp.self, serviceType: PlayerEngineCoreService.self)
        registerSet.addEntry(compClass: PlayerViewComp.self, serviceType: PlayerViewService.self)
        registerSet.addEntry(compClass: PlayerProcessComp.self, serviceType: PlayerProcessService.self)
        registerSet.addEntry(compClass: PlayerPlaybackControlComp.self, serviceType: PlayerPlaybackControlService.self)
        registerSet.addEntry(compClass: PlayerSpeedComp.self, serviceType: PlayerSpeedService.self)
        registerSet.addEntry(compClass: PlayerSpeedPanelComp.self, serviceType: PlayerSpeedPanelService.self)
        registerSet.addEntry(compClass: PlayerLoopingComp.self, serviceType: PlayerLoopingService.self)
        registerSet.addEntry(compClass: PlayerTimeControlComp.self, serviceType: PlayerTimeControlService.self)
        registerSet.addEntry(compClass: PlayerAppActiveComp.self, serviceType: PlayerAppActiveService.self)
        registerSet.addEntry(compClass: PlayerMediaControlComp.self, serviceType: PlayerMediaControlService.self)
        registerSet.addEntry(compClass: PlayerFullScreenComp.self, serviceType: PlayerFullScreenService.self)
        registerSet.addEntry(compClass: PlayerControlViewComp.self, serviceType: PlayerControlViewService.self)
        registerSet.addEntry(compClass: PlayerReplayComp.self, serviceType: PlayerReplayService.self)
        registerSet.addEntry(compClass: PlayerFinishViewComp.self, serviceType: PlayerFinishViewService.self)
        registerSet.addEntry(compClass: PlayerCoverMaskComp.self, serviceType: PlayerCoverMaskService.self)
        registerSet.addEntry(compClass: PlayerPanelComp.self, serviceType: PlayerPanelService.self)
        registerSet.addEntry(compClass: PlayerTrackerComp.self, serviceType: PlayerTrackerService.self)
        registerSet.addEntry(compClass: PlayerQosComp.self, serviceType: PlayerQosService.self)
        registerSet.addEntry(compClass: PlayerResolutionComp.self, serviceType: PlayerResolutionService.self)
        registerSet.addEntry(compClass: PlayerPreRenderComp.self, serviceType: PlayerPreRenderService.self)
        registerSet.addEntry(compClass: PlayerContextComp.self, serviceType: PlayerContextService.self)
        registerSet.addEntry(compClass: PlayerDebugComp.self, serviceType: PlayerDebugService.self)
        registerSet.addEntry(compClass: PlayerPreNextComp.self, serviceType: PlayerPreNextService.self)
        registerSet.addEntry(compClass: PlayerTipManagerComp.self, serviceType: PlayerTipManagerService.self)
        registerSet.addEntry(compClass: PlayerToastComp.self, serviceType: PlayerToastService.self)
        registerSet.addEntry(compClass: PlayerPreloadComp.self, serviceType: PlayerPreloadService.self)
        registerSet.addEntry(compClass: PlayerStartTimeComp.self, serviceType: PlayerStartTimeService.self)
        registerSet.addEntry(compClass: PlayerGestureComp.self, serviceType: PlayerGestureService.self)
        registerSet.addEntry(compClass: PlayerSubtitleComp.self, serviceType: PlayerSubtitleService.self)
        registerSet.addEntry(compClass: PlayerSnapshotComp.self, serviceType: PlayerSnapshotService.self)
    }
}

@MainActor
public final class Player: CCLContextHolder {

    public let context: CCLPublicContext

    private let regProvider = PlayerRegProvider()

    public init(name: String? = nil) {
        let ctx = CCLContext(name: name ?? "Player")
        self.context = ctx
        ctx.addRegProvider(regProvider)
    }

    // MARK: - Engine Pool

    private var _sharedPool: PlayerEnginePoolService?
    private var _poolIdentifier: String?

    public func bindPool(_ pool: PlayerEnginePoolService, identifier: String) {
        _sharedPool = pool
        _poolIdentifier = identifier
    }

    @discardableResult
    public func acquireEngine() -> Bool {
        guard let pool = _sharedPool, let id = _poolIdentifier else { return false }
        guard let engine = pool.dequeue(identifier: id) else { return false }
        guard let comp = engine as? CCLBaseComp else { return false }
        context.detachInstance(for: PlayerEngineCoreService.self)
        context.registerInstance(comp, protocol: PlayerEngineCoreService.self)
        return true
    }

    public func recycleEngine() {
        guard let pool = _sharedPool, let id = _poolIdentifier else { return }
        engineService?.pause()
        guard let comp = context.detachInstance(for: PlayerEngineCoreService.self) else { return }
        guard let engine = comp as? PlayerEngineCoreService else { return }
        pool.enqueue(engine, identifier: id)
    }

    // MARK: - 便捷服务访问

    public var dataService: PlayerDataService? {
        context.resolveService(PlayerDataService.self)
    }

    public var processService: PlayerProcessService? {
        context.resolveService(PlayerProcessService.self)
    }

    public var trackerService: PlayerTrackerService? {
        context.resolveService(PlayerTrackerService.self)
    }

    public var viewService: PlayerViewService? {
        context.resolveService(PlayerViewService.self)
    }

    public var engineCoreService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    public var speedService: PlayerSpeedService? {
        context.resolveService(PlayerSpeedService.self)
    }

    public var engineService: PlayerEngineCoreService? {
        return engineCoreService
    }

    public var preloadService: PlayerPreloadService? {
        context.resolveService(PlayerPreloadService.self)
    }

    public var startTimeService: PlayerStartTimeService? {
        context.resolveService(PlayerStartTimeService.self)
    }

    public var gestureService: PlayerGestureService? {
        context.resolveService(PlayerGestureService.self)
    }

    public var subtitleService: PlayerSubtitleService? {
        context.resolveService(PlayerSubtitleService.self)
    }

    public var snapshotService: PlayerSnapshotService? {
        context.resolveService(PlayerSnapshotService.self)
    }

    public var speedPanelService: PlayerSpeedPanelService? {
        context.resolveService(PlayerSpeedPanelService.self)
    }
}
