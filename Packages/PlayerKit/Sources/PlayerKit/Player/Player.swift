//
//  Player.swift
//  playerkit
//

import Foundation
import UIKit
import AVFoundation

/** 播放器注册提供者，注册所有基础层播放插件 */
@MainActor
final class PlayerRegProvider: RegisterProvider {
    /** 向注册集合中注册所有核心播放器插件 */
    func registerPlugins(with registerSet: PluginRegisterSet) {
        // 核心插件
        registerSet.addEntry(pluginClass: PlayerDataPlugin.self, serviceType: PlayerDataService.self)
        registerSet.addEntry(pluginClass: PlayerEngineCorePlugin.self, serviceType: PlayerEngineCoreService.self)
        registerSet.addEntry(pluginClass: PlayerViewPlugin.self, serviceType: PlayerViewService.self)
        registerSet.addEntry(pluginClass: PlayerProcessPlugin.self, serviceType: PlayerProcessService.self)
        registerSet.addEntry(pluginClass: PlayerPlaybackControlPlugin.self, serviceType: PlayerPlaybackControlService.self)
        registerSet.addEntry(pluginClass: PlayerSpeedPlugin.self, serviceType: PlayerSpeedService.self)
        registerSet.addEntry(pluginClass: PlayerLoopingPlugin.self, serviceType: PlayerLoopingService.self)
        registerSet.addEntry(pluginClass: PlayerTimeControlPlugin.self, serviceType: PlayerTimeControlService.self)
        registerSet.addEntry(pluginClass: PlayerAppActivePlugin.self, serviceType: PlayerAppActiveService.self)
        registerSet.addEntry(pluginClass: PlayerMediaControlPlugin.self, serviceType: PlayerMediaControlService.self)
        registerSet.addEntry(pluginClass: PlayerPreRenderPlugin.self, serviceType: PlayerPreRenderService.self)
        registerSet.addEntry(pluginClass: PlayerStartTimePlugin.self, serviceType: PlayerStartTimeService.self)
        registerSet.addEntry(pluginClass: PlayerSnapshotPlugin.self, serviceType: PlayerSnapshotService.self)
        // 引擎池服务（全局单例访问入口）
        registerSet.addEntry(pluginClass: PlayerEnginePoolPlugin.self, serviceType: PlayerEnginePoolService.self)
        // HTTP 代理服务（视频缓存）
        registerSet.addEntry(pluginClass: PlayerHTTPProxyPlugin.self, serviceType: PlayerHTTPProxyService.self)
    }
}

/** 主播放器类，基于插件化架构管理播放器核心功能 */
@MainActor
public final class Player: ContextHolder {

    /** 播放器的 Context 实例 */
    public let context: PublicContext

    /** 播放器注册提供者 */
    private let regProvider = PlayerRegProvider()

    /** 初始化播放器，可指定名称 */
    public init(name: String? = nil) {
        let ctx = Context(name: name ?? "Player")
        self.context = ctx
        ctx.addRegProvider(regProvider)
    }

    // MARK: - Engine Pool

    /** 引擎池标识符（用于从池中获取/回收引擎） */
    private var _poolIdentifier: String?

    /** 引擎池服务，通过 Context 获取全局池 */
    public var poolService: PlayerEnginePoolService? {
        context.resolveService(PlayerEnginePoolService.self)
    }

    /** 绑定引擎池标识符，用于引擎复用 */
    public func bindPool(identifier: String) {
        _poolIdentifier = identifier
    }

    /** 绑定外部引擎池（兼容旧 API） */
    public func bindPool(_ pool: PlayerEnginePoolService, identifier: String) {
        _poolIdentifier = identifier
        // 外部池通过 Context 注册，这里只记录标识符
    }

    /** 从引擎池中获取引擎实例 */
    @discardableResult
    public func acquireEngine() -> Bool {
        guard let pool = poolService, let id = _poolIdentifier else { return false }
        guard let engine = pool.dequeue(identifier: id) else { return false }
        guard let comp = engine as? BasePlugin else { return false }
        context.detachInstance(for: PlayerEngineCoreService.self)
        context.registerInstance(comp, protocol: PlayerEngineCoreService.self)
        return true
    }

    /** 回收引擎实例到引擎池 */
    public func recycleEngine() {
        guard let pool = poolService, let id = _poolIdentifier else { return }
        engineService?.pause()
        guard let comp = context.detachInstance(for: PlayerEngineCoreService.self) else { return }
        guard let engine = comp as? PlayerEngineCoreService else { return }
        pool.enqueue(engine, identifier: id)
    }

    @discardableResult
    public func adoptEngine(from source: Player) -> Bool {
        recycleEngine()
        context.detachInstance(for: PlayerEngineCoreService.self)
        guard let engine = source.context.detachInstance(for: PlayerEngineCoreService.self) else { return false }
        context.registerInstance(engine, protocol: PlayerEngineCoreService.self)
        (engine as? PlayerEngineCoreService)?.volume = 1.0
        return true
    }

    // MARK: - 便捷服务访问

    /** 数据服务，管理视频数据模型 */
    public var dataService: PlayerDataService? {
        context.resolveService(PlayerDataService.self)
    }

    /** 流程服务，管理播放流程状态 */
    public var processService: PlayerProcessService? {
        context.resolveService(PlayerProcessService.self)
    }

    /** 视图服务，管理播放器视图层级 */
    public var viewService: PlayerViewService? {
        context.resolveService(PlayerViewService.self)
    }

    /** 引擎核心服务，提供底层播放能力 */
    public var engineCoreService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    /** 倍速服务，管理播放倍速 */
    public var speedService: PlayerSpeedService? {
        context.resolveService(PlayerSpeedService.self)
    }

    /** 引擎服务的便捷别名 */
    public var engineService: PlayerEngineCoreService? {
        return engineCoreService
    }

    /** 起播时间服务，管理视频起播时间点 */
    public var startTimeService: PlayerStartTimeService? {
        context.resolveService(PlayerStartTimeService.self)
    }

    /** 截图服务，管理视频截图功能 */
    public var snapshotService: PlayerSnapshotService? {
        context.resolveService(PlayerSnapshotService.self)
    }
}
