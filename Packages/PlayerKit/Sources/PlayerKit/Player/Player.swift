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
        // 预渲染池服务（全局单例访问入口）
        registerSet.addEntry(pluginClass: PlayerPreRenderPoolPlugin.self, serviceType: PlayerPreRenderPoolService.self)
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

    @PlayerPlugin public var poolService: PlayerEnginePoolService?

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

    @PlayerPlugin public var dataService: PlayerDataService?
    @PlayerPlugin public var processService: PlayerProcessService?
    @PlayerPlugin public var viewService: PlayerViewService?
    @PlayerPlugin public var engineCoreService: PlayerEngineCoreService?
    @PlayerPlugin public var speedService: PlayerSpeedService?
    @PlayerPlugin public var startTimeService: PlayerStartTimeService?
    @PlayerPlugin public var snapshotService: PlayerSnapshotService?
    @PlayerPlugin public var preRenderPoolService: PlayerPreRenderPoolService?
    @PlayerPlugin public var preRenderService: PlayerPreRenderService?
    @PlayerPlugin public var playbackControlService: PlayerPlaybackControlService?
    @PlayerPlugin public var loopingService: PlayerLoopingService?
    @PlayerPlugin public var timeControlService: PlayerTimeControlService?
    @PlayerPlugin public var mediaControlService: PlayerMediaControlService?

    public var engineService: PlayerEngineCoreService? {
        return engineCoreService
    }

    // MARK: - Engine Acquisition

    /** 确保播放器拥有可用引擎（预渲染池优先，引擎池兜底） */
    @discardableResult
    public func ensureEngine() -> Bool {
        if engineService?.avPlayer?.currentItem != nil { return true }

        // 优先从预渲染池获取
        if let vid = dataService?.dataModel.vid,
           let pool = preRenderPoolService {
            if let entry = pool.entry(for: vid),
               let videoURL = dataService?.dataModel.videoURL,
               entry.url == videoURL,
               let engine = pool.consume(identifier: vid),
               let comp = engine as? BasePlugin {
                context.detachInstance(for: PlayerEngineCoreService.self)
                context.registerInstance(comp, protocol: PlayerEngineCoreService.self)
                engine.volume = 1.0
                engine.isLooping = false
                return true
            }
            pool.cancel(identifier: vid)
        }

        // 兜底：从引擎池获取
        return acquireEngine()
    }

    /** 绑定预渲染引擎到当前播放器 */
    @discardableResult
    public func adoptEngine(fromPreRender identifier: String) -> Bool {
        guard let pool = preRenderPoolService else { return false }
        return pool.consumeAndTransfer(identifier: identifier, to: self)
    }
}
