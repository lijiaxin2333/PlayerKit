//
//  PlayerPlugin.swift
//  PlayerKit
//

import Foundation

// MARK: - @PlayerPlugin 宏支持

@MainActor
public protocol ServiceAccessible: AnyObject {
    var __pluginContext: ContextProtocol? { get }
}

public enum __PluginInjector {
    @MainActor
    public static func resolve<Service>(_ serviceType: Service.Type, context: ContextProtocol?) -> Service? {
        guard let context = context else { return nil }
        return context.resolveServiceByType(serviceType) as? Service
    }
}

// MARK: - BasePlugin + ServiceAccessible

extension BasePlugin: ServiceAccessible {

    public var __pluginContext: ContextProtocol? {
        return context
    }
}

// MARK: - ContextHolder + ServiceAccessible

extension ContextHolder {

    public var __pluginContext: ContextProtocol? {
        return context
    }
}

/// 服务注入宏，自动从 Context 解析服务实例
///
/// 可在任何遵循 `ServiceAccessible` 或 `ContextHolder` 的类中使用：
///
/// ```swift
/// // Plugin 中
/// class MyPlugin: BasePlugin {
///     @PlayerPlugin var engineService: PlayerEngineCoreService?
/// }
///
/// // ScenePlayer / ViewController / 任何 ContextHolder 中
/// class MyScenePlayer: ContextHolder {
///     let context: PublicContext
///     @PlayerPlugin var engineService: PlayerEngineCoreService?
/// }
///
/// // 任意类，遵循 ServiceAccessible 即可
/// class MyHelper: ServiceAccessible {
///     weak var context: ContextProtocol?
///     var __pluginContext: ContextProtocol? { context }
///     @PlayerPlugin var speedService: PlayerSpeedService?
/// }
/// ```
@attached(accessor)
public macro PlayerPlugin() = #externalMacro(module: "PlayerKitMacros", type: "PlayerPluginMacro")
