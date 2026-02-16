//
//  Player.swift
//  playerkit
//
//  基于插件化架构的主播放器类（简化版）
//

import Foundation
import UIKit
import AVFoundation

@MainActor
final class PlayerRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        registerSet.addEntry(pluginClass: PlayerDataPlugin.self, serviceType: PlayerDataService.self)
        registerSet.addEntry(pluginClass: PlayerEngineCorePlugin.self, serviceType: PlayerEngineCoreService.self)
        registerSet.addEntry(pluginClass: PlayerViewPlugin.self, serviceType: PlayerViewService.self)
        registerSet.addEntry(pluginClass: PlayerProcessPlugin.self, serviceType: PlayerProcessService.self)
        registerSet.addEntry(pluginClass: PlayerPlaybackControlPlugin.self, serviceType: PlayerPlaybackControlService.self)
        registerSet.addEntry(pluginClass: PlayerSpeedPlugin.self, serviceType: PlayerSpeedService.self)
        registerSet.addEntry(pluginClass: PlayerSpeedPanelPlugin.self, serviceType: PlayerSpeedPanelService.self)
        registerSet.addEntry(pluginClass: PlayerLoopingPlugin.self, serviceType: PlayerLoopingService.self)
        registerSet.addEntry(pluginClass: PlayerTimeControlPlugin.self, serviceType: PlayerTimeControlService.self)
        registerSet.addEntry(pluginClass: PlayerAppActivePlugin.self, serviceType: PlayerAppActiveService.self)
        registerSet.addEntry(pluginClass: PlayerMediaControlPlugin.self, serviceType: PlayerMediaControlService.self)
        registerSet.addEntry(pluginClass: PlayerFullScreenPlugin.self, serviceType: PlayerFullScreenService.self)
        registerSet.addEntry(pluginClass: PlayerControlViewPlugin.self, serviceType: PlayerControlViewService.self)
        registerSet.addEntry(pluginClass: PlayerReplayPlugin.self, serviceType: PlayerReplayService.self)
        registerSet.addEntry(pluginClass: PlayerFinishViewPlugin.self, serviceType: PlayerFinishViewService.self)
        registerSet.addEntry(pluginClass: PlayerCoverMaskPlugin.self, serviceType: PlayerCoverMaskService.self)
        registerSet.addEntry(pluginClass: PlayerPanelPlugin.self, serviceType: PlayerPanelService.self)
        registerSet.addEntry(pluginClass: PlayerTrackerPlugin.self, serviceType: PlayerTrackerService.self)
        registerSet.addEntry(pluginClass: PlayerQosPlugin.self, serviceType: PlayerQosService.self)
        registerSet.addEntry(pluginClass: PlayerResolutionPlugin.self, serviceType: PlayerResolutionService.self)
        registerSet.addEntry(pluginClass: PlayerPreRenderPlugin.self, serviceType: PlayerPreRenderService.self)
        registerSet.addEntry(pluginClass: PlayerContextPlugin.self, serviceType: PlayerContextService.self)
        registerSet.addEntry(pluginClass: PlayerDebugPlugin.self, serviceType: PlayerDebugService.self)
        registerSet.addEntry(pluginClass: PlayerPreNextPlugin.self, serviceType: PlayerPreNextService.self)
        registerSet.addEntry(pluginClass: PlayerTipManagerPlugin.self, serviceType: PlayerTipManagerService.self)
        registerSet.addEntry(pluginClass: PlayerToastPlugin.self, serviceType: PlayerToastService.self)
        registerSet.addEntry(pluginClass: PlayerPreloadPlugin.self, serviceType: PlayerPreloadService.self)
        registerSet.addEntry(pluginClass: PlayerStartTimePlugin.self, serviceType: PlayerStartTimeService.self)
        registerSet.addEntry(pluginClass: PlayerGesturePlugin.self, serviceType: PlayerGestureService.self)
        registerSet.addEntry(pluginClass: PlayerSubtitlePlugin.self, serviceType: PlayerSubtitleService.self)
        registerSet.addEntry(pluginClass: PlayerSnapshotPlugin.self, serviceType: PlayerSnapshotService.self)
    }
}

@MainActor
public final class Player: ContextHolder {

    public let context: PublicContext

    private let regProvider = PlayerRegProvider()

    public init(name: String? = nil) {
        let ctx = Context(name: name ?? "Player")
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
        guard let comp = engine as? BasePlugin else { return false }
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
