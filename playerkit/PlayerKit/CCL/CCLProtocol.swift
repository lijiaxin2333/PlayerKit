//
//  CCLProtocol.swift
//  playerkit
//
//  CCL 核心协议定义
//

import Foundation

// MARK: - CCL 事件定义

public typealias CCLEvent = String

// MARK: - CCL 事件处理器协议

@MainActor
public protocol CCLEventHandlerProtocol: AnyObject {

    /// 添加事件监听
    /// - Parameters:
    ///   - observer: 监听者
    ///   - event: 事件名称
    ///   - handler: 事件回调
    /// - Returns: handler token，可用于移除监听
    @discardableResult
    func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject?

    /// 添加多个事件监听
    /// - Parameters:
    ///   - observer: 监听者
    ///   - events: 事件名称数组
    ///   - handler: 事件回调
    /// - Returns: handler token
    @discardableResult
    func add(_ observer: AnyObject, events: [CCLEvent], handler: @escaping CCLEventHandlerBlock) -> AnyObject?

    /// 添加带选项的事件监听
    /// - Parameters:
    ///   - observer: 监听者
    ///   - event: 事件名称
    ///   - option: 监听选项
    ///   - handler: 事件回调
    /// - Returns: handler token
    @discardableResult
    func add(_ observer: AnyObject, event: CCLEvent, option: CCLEventOption, handler: @escaping CCLEventHandlerBlock) -> AnyObject?

    /// 移除监听
    /// - Parameter handler: 通过添加 handler 返回的对象来移除监听
    func removeHandler(_ handler: AnyObject)

    /// 移除该 observer 所有相关的 handler
    /// - Parameter observer: 监听者
    func removeHandlers(forObserver observer: AnyObject)

    /// 移除所有监听
    func removeAllHandler()

    /// 发布事件
    /// - Parameters:
    ///   - event: 事件名称
    ///   - object: 事件相关信息
    ///   - sender: 事件发布者
    func post(_ event: CCLEvent, object: Any?, sender: AnyObject)

    /// 发布不携带数据的事件
    /// - Parameters:
    ///   - event: 事件名称
    ///   - sender: 事件发布者
    func post(_ event: CCLEvent, sender: AnyObject)
}

public typealias CCLEventHandlerBlock = (_ object: Any?, _ event: CCLEvent) -> Void

// MARK: - CCL 事件选项

public struct CCLEventOption: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 默认选项
    public static let none = CCLEventOption(rawValue: 0)

    /// 添加监听时直接执行一次回调
    public static let execWhenAdd = CCLEventOption(rawValue: 1 << 0)

    /// 添加监听后只执行一次回调（执行后自动 remove）
    public static let execOnlyOnce = CCLEventOption(rawValue: 1 << 1)
}

// MARK: - CCL 服务发现协议

@MainActor
public protocol CCLServiceDiscovery: AnyObject {

    /// 通过服务协议类型解析服务
    /// - Parameter serviceProtocol: 服务协议类型
    /// - Returns: 服务实例
    func resolveService<T>(_ serviceProtocol: T.Type) -> T?

    /// 尝试服务发现（不强制检查失败）
    /// - Parameter serviceProtocol: 服务协议类型
    /// - Returns: 服务实例
    func tryResolveService<T>(_ serviceProtocol: T.Type) -> T?

    /// 通过类型元数据解析服务（用于属性包装器等场景）
    /// - Parameter type: 服务协议类型
    /// - Returns: 服务实例
    func resolveServiceByType(_ type: Any.Type) -> Any?

    /// 检查服务是否已注册
    /// - Parameter serviceProtocol: 服务协议类型
    /// - Returns: 是否已注册
    func checkService<T>(_ serviceProtocol: T.Type) -> Bool

    /// 配置已注册的 Component
    /// - Parameters:
    ///   - serviceProtocol: 服务协议类型
    ///   - configModel: 配置数据
    func configComp<T>(serviceProtocol: T.Type, withModel configModel: Any?)
}

// MARK: - CCL 服务注册协议

@MainActor
public protocol CCLCompRegisterProtocol: AnyObject {

    func unregisterService<T>(_ serviceProtocol: T.Type)

    func unregisterCompClass(_ compClass: AnyClass)

    func batchRegister(createType: CCLCompCreateType, events: [CCLEvent]?, registerBlock: (CCLCompRegisterProtocol) -> Void)

    func addRegProvider(_ provider: CCLRegisterProvider)

    func removeRegProvider(_ provider: CCLRegisterProvider)

    func updateRegistryBlacklist(_ blacklist: Set<String>?)
}

// MARK: - CCL 组件创建选项

public struct CCLCompCreateOption: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 闲时创建
    public static let idle = CCLCompCreateOption(rawValue: 1 << 0)

    /// 注册时创建
    public static let whenRegistered = CCLCompCreateOption(rawValue: 1 << 1)
}

// MARK: - CCL 组件创建时机

public struct CCLCompCreateType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// 默认方式，注册时就创建实例
    public static let whenRegistered = CCLCompCreateType(rawValue: 1 << 0)

    /// 第一次配置时创建实例
    public static let whenFirstConfig = CCLCompCreateType(rawValue: 1 << 1)

    /// 第一次 resolve service 时创建实例
    public static let whenFirstResolve = CCLCompCreateType(rawValue: 1 << 2)

    /// 指定事件被 post 时才创建
    public static let whenPostEvent = CCLCompCreateType(rawValue: 1 << 3)
}

// MARK: - CCL Context 协议

@MainActor
public protocol CCLContextProtocol: CCLEventHandlerProtocol, CCLServiceDiscovery, CCLCompRegisterProtocol {

    /// Context 名称
    var name: String? { get }

    /// Context 持有者
    var holder: CCLContextHolder? { get }

    /// 父 Context
    var superContext: CCLPublicContext? { get }
}

// MARK: - CCL 公共 Context 协议

@MainActor
public protocol CCLPublicContext: CCLContextProtocol {

    /// 添加子 Context
    /// - Parameter subContext: 子 Context
    func addSubContext(_ subContext: CCLPublicContext)

    /// 添加子 Context 并进行配置
    /// - Parameters:
    ///   - subContext: 子 Context
    ///   - buildBlock: 配置 block
    func addSubContext(_ subContext: CCLPublicContext, buildBlock: ((CCLCompRegisterProtocol, CCLCompRegisterProtocol) -> Void)?)

    /// 移除子 Context
    /// - Parameter subContext: 子 Context
    func removeSubContext(_ subContext: CCLPublicContext)

    /// 从父 Context 中移除自己
    func removeFromSuperContext()

    /// 检查是否是某个 Context 的后代
    /// - Parameter context: 父 Context
    /// - Returns: 是否是后代
    func isDescendant(of context: CCLPublicContext) -> Bool

    /// 检查是否是某个 Context 的祖先
    /// - Parameter context: 子 Context
    /// - Returns: 是否是祖先
    func isAncestor(of context: CCLPublicContext) -> Bool

    /// 绑定共享 Context
    /// - Parameter context: 共享 Context
    func bindSharedContext(_ context: CCLSharedContextProtocol)

    func registerInstance(_ comp: CCLBaseComp, protocol serviceProtocol: Any.Type)

    func detachInstance(for serviceProtocol: Any.Type) -> CCLBaseComp?
}

// MARK: - CCL 扩展 Context 协议

@MainActor
public protocol CCLExtendContext: AnyObject {

    func addExtendContext(_ context: CCLPublicContext)

    func removeExtendContext(_ context: CCLPublicContext)

    func removeFromBaseContext()

    func isExtension(of context: CCLPublicContext) -> Bool

    func isBaseContext(of context: CCLPublicContext) -> Bool
}

// MARK: - CCL 共享 Context 协议

public protocol CCLSharedContextProtocol: CCLServiceDiscovery, CCLCompRegisterProtocol {

}

// MARK: - CCL Context Holder 协议

public protocol CCLContextHolder: AnyObject {

    /// Context 实例
    var context: CCLPublicContext { get }
}

// MARK: - CCL 组件协议

@MainActor
public protocol CCLCompProtocol: AnyObject {

    /// 组件所在的 context
    var context: CCLContextProtocol? { get set }

    /// 声明依赖的服务协议列表
    /// - Returns: 依赖的服务协议类型数组
    static func cclDependencyProtocols() -> [Any.Type]?

    /// 是否忽略依赖检查
    /// - Returns: 是否忽略
    static func cclIgnoreDependencyProtocols() -> Bool

    /// 声明需要 post 的 events
    /// - Returns: 事件数组
    static func cclBindedEvents() -> [CCLEvent]?

    /// 组件加载到 context
    /// - Parameter context: 加入的 context
    func componentDidLoad(_ context: CCLContextProtocol)

    /// 组件即将从 context 移除
    /// - Parameter context: 之前所在的 context
    func componentWillUnload(_ context: CCLContextProtocol)

    /// 配置组件
    /// - Parameter configModel: 配置数据
    func config(_ configModel: Any?)
}

// MARK: - CCL 组件服务协议

@MainActor
public protocol CCLCompService: AnyObject {

    /// 配置组件
    /// - Parameter configModel: 配置数据
    func config(_ configModel: Any?)
}

// MARK: - 默认实现

public extension CCLCompProtocol {

    static func cclDependencyProtocols() -> [Any.Type]? {
        return nil
    }

    static func cclIgnoreDependencyProtocols() -> Bool {
        return false
    }

    static func cclBindedEvents() -> [CCLEvent]? {
        return nil
    }
}

// MARK: - CCL 注册条目

public final class CCLCompRegEntryInfo {

    public let compClass: AnyClass
    public let serviceType: Any.Type?
    public let serviceKey: String?
    public var options: CCLCompCreateOption

    public init(compClass: AnyClass, serviceType: Any.Type?, options: CCLCompCreateOption = []) {
        self.compClass = compClass
        self.serviceType = serviceType
        self.serviceKey = serviceType.map { _typeName($0, qualified: false) }
        self.options = options
    }

    public var identifier: String {
        serviceKey ?? NSStringFromClass(compClass)
    }
}

// MARK: - CCL 创建分组

public final class CCLCompCreateGroupInfo: Hashable {

    public var createType: CCLCompCreateType
    public var createEvents: [CCLEvent]?

    public init(createType: CCLCompCreateType = .whenRegistered, createEvents: [CCLEvent]? = nil) {
        self.createType = createType
        self.createEvents = createEvents
    }

    public static func == (lhs: CCLCompCreateGroupInfo, rhs: CCLCompCreateGroupInfo) -> Bool {
        lhs.createType == rhs.createType && lhs.createEvents == rhs.createEvents
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createType.rawValue)
        hasher.combine(createEvents)
    }
}

// MARK: - CCL 组件注册集

public final class CCLCompRegisterSet {

    private var entries: [CCLCompRegEntryInfo] = []
    private var groupConfigs: [String: CCLCompCreateGroupInfo] = [:]
    private var defaultGroup = CCLCompCreateGroupInfo(createType: .whenRegistered)

    public init() {}

    public func addEntry(compClass: AnyClass, serviceType: Any.Type?, options: CCLCompCreateOption = []) {
        let entry = CCLCompRegEntryInfo(compClass: compClass, serviceType: serviceType, options: options)
        entries.append(entry)
    }

    public func removeEntry(serviceKey: String) {
        entries.removeAll { $0.serviceKey == serviceKey }
    }

    public func removeEntry(compClass: AnyClass) {
        entries.removeAll { $0.compClass === compClass }
    }

    public func configCreateType(_ createType: CCLCompCreateType, createEvents: [CCLEvent]? = nil, entryIDs: [String]) {
        let group = CCLCompCreateGroupInfo(createType: createType, createEvents: createEvents)
        for id in entryIDs {
            groupConfigs[id] = group
        }
    }

    public func allEntries() -> [CCLCompRegEntryInfo] {
        entries
    }

    public func createGroup(for entry: CCLCompRegEntryInfo) -> CCLCompCreateGroupInfo {
        groupConfigs[entry.identifier] ?? defaultGroup
    }

    public func allCreateGroups() -> [CCLCompCreateGroupInfo] {
        var groups = Set<CCLCompCreateGroupInfo>()
        groups.insert(defaultGroup)
        for group in groupConfigs.values {
            groups.insert(group)
        }
        return Array(groups)
    }

    public func entries(for group: CCLCompCreateGroupInfo) -> [CCLCompRegEntryInfo] {
        entries.filter { createGroup(for: $0) == group }
    }
}

// MARK: - CCL 注册提供者协议

@MainActor
public protocol CCLRegisterProvider: AnyObject {

    func registerComps(with registerSet: CCLCompRegisterSet)

    func configCompCreate(_ registerSet: CCLCompRegisterSet)
}

public extension CCLRegisterProvider {

    func configCompCreate(_ registerSet: CCLCompRegisterSet) {}
}
