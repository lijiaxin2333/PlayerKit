//
//  Protocol.swift
//  playerkit
//

import Foundation

/** 事件类型别名，使用字符串标识事件 */
public typealias Event = String

/** 事件处理协议，定义事件监听、移除和发送的能力 */
@MainActor
public protocol EventHandlerProtocol: AnyObject {

    /** 添加单个事件监听器 */
    @discardableResult
    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject?

    /** 添加多个事件的监听器 */
    @discardableResult
    func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject?

    /** 添加带选项的事件监听器 */
    @discardableResult
    func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject?

    /** 通过 handler token 移除指定事件处理器 */
    func removeHandler(_ handler: AnyObject)

    /** 移除指定观察者的所有事件处理器 */
    func removeHandlers(forObserver observer: AnyObject)

    /** 移除所有事件处理器 */
    func removeAllHandler()

    /** 发送事件，携带附加数据 */
    func post(_ event: Event, object: Any?, sender: AnyObject)

    /** 发送事件，不携带附加数据 */
    func post(_ event: Event, sender: AnyObject)
}

/** 事件处理回调闭包类型 */
public typealias EventHandlerBlock = (_ object: Any?, _ event: Event) -> Void

/** 事件监听选项，控制事件处理器的行为 */
public struct EventOption: OptionSet, Sendable {
    /** 选项原始值 */
    public let rawValue: UInt

    /** 初始化事件选项 */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /** 无特殊选项 */
    public static let none = EventOption([])

    /** 注册时立即执行一次回调 */
    public static let execWhenAdd = EventOption(rawValue: 1 << 0)

    /** 仅执行一次后自动移除 */
    public static let execOnlyOnce = EventOption(rawValue: 1 << 1)
}

/** 服务发现协议，提供通过协议类型查找和配置服务的能力 */
@MainActor
public protocol ServiceDiscovery: AnyObject {

    /** 解析服务实例，未找到时打印警告并返回 nil */
    func resolveService<T>(_ serviceProtocol: T.Type) -> T?

    /** 尝试解析服务实例，未找到时静默返回 nil */
    func tryResolveService<T>(_ serviceProtocol: T.Type) -> T?

    /** 通过类型解析服务实例 */
    func resolveServiceByType(_ type: Any.Type) -> Any?

    /** 检查指定服务是否已注册 */
    func checkService<T>(_ serviceProtocol: T.Type) -> Bool

    /** 配置指定服务协议对应的插件 */
    func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?)
}

/** 插件注册协议，提供插件注册、注销和批量管理的能力 */
@MainActor
public protocol PluginRegisterProtocol: AnyObject {

    /** 注销指定服务协议对应的插件 */
    func unregisterService<T>(_ serviceProtocol: T.Type)

    /** 注销指定类的插件 */
    func unregisterPluginClass(_ pluginClass: AnyClass)

    /** 批量注册插件，支持指定创建类型和触发事件 */
    func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void)

    /** 添加注册提供者，自动执行其注册逻辑 */
    func addRegProvider(_ provider: RegisterProvider)

    /** 移除注册提供者并注销其注册的所有插件 */
    func removeRegProvider(_ provider: RegisterProvider)

    /** 更新注册黑名单，黑名单中的插件将被阻止注册或被移除 */
    func updateRegistryBlacklist(_ blacklist: Set<String>?)
}

/** 插件创建选项，控制插件的创建时机 */
public struct PluginCreateOption: OptionSet, Sendable {
    /** 选项原始值 */
    public let rawValue: UInt

    /** 初始化插件创建选项 */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /** 空闲时创建 */
    public static let idle = PluginCreateOption(rawValue: 1 << 0)

    /** 注册时立即创建 */
    public static let whenRegistered = PluginCreateOption(rawValue: 1 << 1)
}

/** 插件创建类型，定义插件实例的创建时机策略 */
public struct PluginCreateType: OptionSet, Sendable {
    /** 选项原始值 */
    public let rawValue: UInt

    /** 初始化插件创建类型 */
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /** 注册时立即创建实例 */
    public static let whenRegistered = PluginCreateType(rawValue: 1 << 0)

    /** 首次调用 config 时创建实例 */
    public static let whenFirstConfig = PluginCreateType(rawValue: 1 << 1)

    /** 首次解析服务时创建实例 */
    public static let whenFirstResolve = PluginCreateType(rawValue: 1 << 2)

    /** 收到特定事件时创建实例 */
    public static let whenPostEvent = PluginCreateType(rawValue: 1 << 3)
}

/** Context 协议，整合事件处理、服务发现和插件注册三大能力 */
@MainActor
public protocol ContextProtocol: EventHandlerProtocol, ServiceDiscovery, PluginRegisterProtocol {

    /** Context 的名称标识 */
    var name: String? { get }

    /** Context 的持有者 */
    var holder: ContextHolder? { get }

    /** 父级 Context */
    var superContext: PublicContext? { get }
}

/** 公共 Context 协议，提供子 Context 管理、共享 Context 绑定和插件实例管理功能 */
@MainActor
public protocol PublicContext: ContextProtocol {

    /** 添加子 Context */
    func addSubContext(_ subContext: PublicContext)

    /** 添加子 Context 并执行构建闭包 */
    func addSubContext(_ subContext: PublicContext, buildBlock: ((PluginRegisterProtocol, PluginRegisterProtocol) -> Void)?)

    /** 移除子 Context */
    func removeSubContext(_ subContext: PublicContext)

    /** 从父 Context 中移除自身 */
    func removeFromSuperContext()

    /** 判断当前 Context 是否是指定 Context 的后代 */
    func isDescendant(of context: PublicContext) -> Bool

    /** 判断当前 Context 是否是指定 Context 的祖先 */
    func isAncestor(of context: PublicContext) -> Bool

    /** 绑定共享 Context */
    func bindSharedContext(_ context: SharedContextProtocol)

    /** 注册已有的插件实例到指定服务协议 */
    func registerInstance(_ plugin: BasePlugin, protocol serviceProtocol: Any.Type)

    /** 分离指定服务协议对应的插件实例 */
    func detachInstance(for serviceProtocol: Any.Type) -> BasePlugin?
}

/** 扩展 Context 协议，用于建立功能扩展关系 */
@MainActor
public protocol ExtendContext: AnyObject {

    /** 添加扩展 Context */
    func addExtendContext(_ context: PublicContext)

    /** 移除扩展 Context */
    func removeExtendContext(_ context: PublicContext)

    /** 从基础 Context 中移除自身 */
    func removeFromBaseContext()

    /** 判断当前 Context 是否是指定 Context 的扩展 */
    func isExtension(of context: PublicContext) -> Bool

    /** 判断当前 Context 是否是指定 Context 的基础 */
    func isBaseContext(of context: PublicContext) -> Bool
}

/** 共享 Context 协议，提供跨多个持有者共享服务的能力 */
public protocol SharedContextProtocol: ServiceDiscovery, PluginRegisterProtocol {

}

/** Context 持有者协议，持有并暴露 Context 实例 */
@MainActor
public protocol ContextHolder: AnyObject {

    /** 持有的 Context 实例 */
    var context: PublicContext { get }
}

/** 插件协议，定义插件的生命周期方法和依赖关系 */
@MainActor
public protocol PluginProtocol: AnyObject {

    /** 插件所属的 Context */
    var context: ContextProtocol? { get set }

    /** 返回插件的依赖服务协议列表 */
    static func dependencyProtocols() -> [Any.Type]?

    /** 是否忽略依赖检查 */
    static func ignoreDependencyProtocols() -> Bool

    /** 返回插件绑定的事件列表 */
    static func bindedEvents() -> [Event]?

    /** 插件加载完成时调用 */
    func pluginDidLoad(_ context: ContextProtocol)

    /** 插件即将卸载时调用 */
    func pluginWillUnload(_ context: ContextProtocol)

    /** 配置插件参数 */
    func config(_ configModel: Any?)
}

/** 插件服务协议，定义服务的配置能力 */
@MainActor
public protocol PluginService: AnyObject {

    /** 配置服务参数 */
    func config(_ configModel: Any?)
}

public extension PluginProtocol {

    /** 默认返回无依赖协议 */
    static func dependencyProtocols() -> [Any.Type]? {
        return nil
    }

    /** 默认不忽略依赖检查 */
    static func ignoreDependencyProtocols() -> Bool {
        return false
    }

    /** 默认无绑定事件 */
    static func bindedEvents() -> [Event]? {
        return nil
    }
}

/** 插件注册条目信息，记录插件类、服务类型和创建选项 */
public final class PluginRegEntryInfo {

    /** 插件类 */
    public let pluginClass: AnyClass
    /** 服务协议类型 */
    public let serviceType: Any.Type?
    /** 服务的字符串标识 */
    public let serviceKey: String?
    /** 插件创建选项 */
    public var options: PluginCreateOption

    /** 初始化插件注册条目 */
    public init(pluginClass: AnyClass, serviceType: Any.Type?, options: PluginCreateOption = []) {
        self.pluginClass = pluginClass
        self.serviceType = serviceType
        self.serviceKey = serviceType.map { String(reflecting: $0) }
        self.options = options
    }

    /** 返回注册条目的唯一标识符 */
    public var identifier: String {
        serviceKey ?? String(reflecting: pluginClass)
    }
}

/** 插件创建分组信息，定义一组插件的创建策略 */
public final class PluginCreateGroupInfo: Hashable {

    /** 创建类型 */
    public var createType: PluginCreateType
    /** 触发创建的事件列表 */
    public var createEvents: [Event]?

    /** 初始化创建分组信息 */
    public init(createType: PluginCreateType = .whenRegistered, createEvents: [Event]? = nil) {
        self.createType = createType
        self.createEvents = createEvents
    }

    /** 判等方法 */
    public static func == (lhs: PluginCreateGroupInfo, rhs: PluginCreateGroupInfo) -> Bool {
        lhs.createType == rhs.createType && lhs.createEvents == rhs.createEvents
    }

    /** 哈希方法 */
    public func hash(into hasher: inout Hasher) {
        hasher.combine(createType.rawValue)
        hasher.combine(createEvents)
    }
}

/** 插件注册集合，管理一组插件注册条目及其创建分组配置 */
public final class PluginRegisterSet {

    /** 注册条目列表 */
    private var entries: [PluginRegEntryInfo] = []
    /** 条目到创建分组的映射 */
    private var groupConfigs: [String: PluginCreateGroupInfo] = [:]
    /** 默认创建分组，注册时立即创建 */
    private var defaultGroup = PluginCreateGroupInfo(createType: .whenRegistered)

    /** 初始化空的注册集合 */
    public init() {}

    /** 添加插件注册条目 */
    public func addEntry(pluginClass: AnyClass, serviceType: Any.Type?, options: PluginCreateOption = []) {
        let entry = PluginRegEntryInfo(pluginClass: pluginClass, serviceType: serviceType, options: options)
        entries.append(entry)
    }

    /** 按服务标识移除注册条目 */
    public func removeEntry(serviceKey: String) {
        entries.removeAll { $0.serviceKey == serviceKey }
    }

    /** 按插件类移除注册条目 */
    public func removeEntry(pluginClass: AnyClass) {
        entries.removeAll { $0.pluginClass === pluginClass }
    }

    /** 配置指定条目的创建类型和触发事件 */
    public func configCreateType(_ createType: PluginCreateType, createEvents: [Event]? = nil, entryIDs: [String]) {
        let group = PluginCreateGroupInfo(createType: createType, createEvents: createEvents)
        for id in entryIDs {
            groupConfigs[id] = group
        }
    }

    /** 返回所有注册条目 */
    public func allEntries() -> [PluginRegEntryInfo] {
        entries
    }

    /** 获取指定条目所属的创建分组 */
    public func createGroup(for entry: PluginRegEntryInfo) -> PluginCreateGroupInfo {
        groupConfigs[entry.identifier] ?? defaultGroup
    }

    /** 返回所有创建分组 */
    public func allCreateGroups() -> [PluginCreateGroupInfo] {
        var groups = Set<PluginCreateGroupInfo>()
        groups.insert(defaultGroup)
        for group in groupConfigs.values {
            groups.insert(group)
        }
        return Array(groups)
    }

    /** 返回属于指定创建分组的所有条目 */
    public func entries(for group: PluginCreateGroupInfo) -> [PluginRegEntryInfo] {
        entries.filter { createGroup(for: $0) == group }
    }
}

/** 注册提供者协议，封装插件注册逻辑 */
@MainActor
public protocol RegisterProvider: AnyObject {

    /** 注册插件到注册集合 */
    func registerPlugins(with registerSet: PluginRegisterSet)

    /** 配置插件创建策略 */
    func configPluginCreate(_ registerSet: PluginRegisterSet)
}

public extension RegisterProvider {

    /** 默认空实现，不配置额外的创建策略 */
    func configPluginCreate(_ registerSet: PluginRegisterSet) {}
}
