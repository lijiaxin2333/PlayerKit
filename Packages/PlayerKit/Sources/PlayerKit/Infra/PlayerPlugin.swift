//
//  PlayerPlugin.swift
//  PlayerKit
//

import Foundation

// MARK: - @PlayerPlugin 宏支持

/// 插件注入辅助类，供 @PlayerPlugin 宏使用
public enum __PluginInjector {
    /// 从 Context 解析服务实例
    @MainActor
    public static func resolve<Service>(_ serviceType: Service.Type, context: ContextProtocol?) -> Service? {
        guard let context = context else {
            return nil
        }
        return context.resolveServiceByType(serviceType) as? Service
    }
}

// MARK: - BasePlugin 扩展

extension BasePlugin {

    /// 插件 Context 访问器，供 @PlayerPlugin 宏使用
    public var __pluginContext: ContextProtocol? {
        return context
    }
}

/// 插件依赖注入宏，自动从 Context 解析服务实例
///
/// 使用示例：
/// ```swift
/// class MyPlugin: BasePlugin {
///     @PlayerPlugin var engineService: PlayerEngineCoreService?
///     @PlayerPlugin var speedService: PlayerSpeedService?
/// }
/// ```
///
/// 展开后：
/// ```swift
/// var engineService: PlayerEngineCoreService? {
///     get { __PluginInjector.resolve(PlayerEngineCoreService.self, context: __pluginContext) }
/// }
/// ```
@attached(accessor)
public macro PlayerPlugin() = #externalMacro(module: "PlayerKitMacros", type: "PlayerPluginMacro")
