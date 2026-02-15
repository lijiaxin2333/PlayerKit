import UIKit

/// 列表插件协议
/// - 实现者: 业务层 Plugin
/// - 职责:
///   1. 持有 ListContext 以访问列表能力
///   2. 声明提供的能力协议
///   3. 声明依赖的其他插件协议
@MainActor
public protocol ListPluginProtocol: ListProtocol {

    /// 列表上下文，用于访问列表的各项能力
    var listContext: ListContext? { get set }

    /// ListContext 加载完成时调用
    func listContextDidLoad()

    /// 返回此插件实现的能力协议列表
    /// - Returns: 协议类型数组，其他组件可通过 responderForProtocol 查询
    func implementProtocols() -> [Any.Type]

    /// 返回此插件依赖的其他插件协议列表
    /// - Returns: 依赖的协议类型数组，用于确保依赖的插件先初始化
    func dependencyProtocols() -> [Any.Type]
}

public extension ListPluginProtocol {

    func listContextDidLoad() {}

    func implementProtocols() -> [Any.Type] { [] }

    func dependencyProtocols() -> [Any.Type] { [] }
}
