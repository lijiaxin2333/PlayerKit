//
//  PlayerKitMacros.swift
//  PlayerKit
//

import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// @PlayerPlugin 宏实现：简化依赖注入属性声明
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
public struct PlayerPluginMacro: AccessorMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) -> [AccessorDeclSyntax] {
        // 确保目标是变量声明
        guard let varDecl = declaration.as(VariableDeclSyntax.self) else {
            return []
        }

        // 获取变量绑定
        guard let binding = varDecl.bindings.first else {
            return []
        }

        // 获取类型
        guard let typeAnnotation = binding.typeAnnotation else {
            return []
        }

        // 获取服务类型（处理 Optional 和非 Optional）
        let serviceType: TypeSyntax
        if let optionalType = typeAnnotation.type.as(OptionalTypeSyntax.self) {
            serviceType = optionalType.wrappedType
        } else {
            serviceType = typeAnnotation.type
        }

        // 生成 getter
        let accessor: AccessorDeclSyntax = """
        get {
            __PluginInjector.resolve(\(serviceType).self, context: __pluginContext)
        }
        """

        return [accessor]
    }
}

/// 编译器插件入口
@main
struct PlayerKitMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        PlayerPluginMacro.self
    ]
}
