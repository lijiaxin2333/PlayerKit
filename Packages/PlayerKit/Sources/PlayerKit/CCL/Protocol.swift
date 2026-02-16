//
//  Protocol.swift
//  playerkit
//

import Foundation

public typealias Event = String

@MainActor
public protocol EventHandlerProtocol: AnyObject {

    @discardableResult
    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject?

    @discardableResult
    func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject?

    @discardableResult
    func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject?

    func removeHandler(_ handler: AnyObject)

    func removeHandlers(forObserver observer: AnyObject)

    func removeAllHandler()

    func post(_ event: Event, object: Any?, sender: AnyObject)

    func post(_ event: Event, sender: AnyObject)
}

public typealias EventHandlerBlock = (_ object: Any?, _ event: Event) -> Void

public struct EventOption: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let none = EventOption(rawValue: 0)

    public static let execWhenAdd = EventOption(rawValue: 1 << 0)

    public static let execOnlyOnce = EventOption(rawValue: 1 << 1)
}

@MainActor
public protocol ServiceDiscovery: AnyObject {

    func resolveService<T>(_ serviceProtocol: T.Type) -> T?

    func tryResolveService<T>(_ serviceProtocol: T.Type) -> T?

    func resolveServiceByType(_ type: Any.Type) -> Any?

    func checkService<T>(_ serviceProtocol: T.Type) -> Bool

    func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?)
}

@MainActor
public protocol PluginRegisterProtocol: AnyObject {

    func unregisterService<T>(_ serviceProtocol: T.Type)

    func unregisterPluginClass(_ pluginClass: AnyClass)

    func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void)

    func addRegProvider(_ provider: RegisterProvider)

    func removeRegProvider(_ provider: RegisterProvider)

    func updateRegistryBlacklist(_ blacklist: Set<String>?)
}

public struct PluginCreateOption: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let idle = PluginCreateOption(rawValue: 1 << 0)

    public static let whenRegistered = PluginCreateOption(rawValue: 1 << 1)
}

public struct PluginCreateType: OptionSet {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let whenRegistered = PluginCreateType(rawValue: 1 << 0)

    public static let whenFirstConfig = PluginCreateType(rawValue: 1 << 1)

    public static let whenFirstResolve = PluginCreateType(rawValue: 1 << 2)

    public static let whenPostEvent = PluginCreateType(rawValue: 1 << 3)
}

@MainActor
public protocol ContextProtocol: EventHandlerProtocol, ServiceDiscovery, PluginRegisterProtocol {

    var name: String? { get }

    var holder: ContextHolder? { get }

    var superContext: PublicContext? { get }
}

@MainActor
public protocol PublicContext: ContextProtocol {

    func addSubContext(_ subContext: PublicContext)

    func addSubContext(_ subContext: PublicContext, buildBlock: ((PluginRegisterProtocol, PluginRegisterProtocol) -> Void)?)

    func removeSubContext(_ subContext: PublicContext)

    func removeFromSuperContext()

    func isDescendant(of context: PublicContext) -> Bool

    func isAncestor(of context: PublicContext) -> Bool

    func bindSharedContext(_ context: SharedContextProtocol)

    func registerInstance(_ plugin: BasePlugin, protocol serviceProtocol: Any.Type)

    func detachInstance(for serviceProtocol: Any.Type) -> BasePlugin?
}

@MainActor
public protocol ExtendContext: AnyObject {

    func addExtendContext(_ context: PublicContext)

    func removeExtendContext(_ context: PublicContext)

    func removeFromBaseContext()

    func isExtension(of context: PublicContext) -> Bool

    func isBaseContext(of context: PublicContext) -> Bool
}

public protocol SharedContextProtocol: ServiceDiscovery, PluginRegisterProtocol {

}

public protocol ContextHolder: AnyObject {

    var context: PublicContext { get }
}

@MainActor
public protocol PluginProtocol: AnyObject {

    var context: ContextProtocol? { get set }

    static func dependencyProtocols() -> [Any.Type]?

    static func ignoreDependencyProtocols() -> Bool

    static func bindedEvents() -> [Event]?

    func pluginDidLoad(_ context: ContextProtocol)

    func pluginWillUnload(_ context: ContextProtocol)

    func config(_ configModel: Any?)
}

@MainActor
public protocol PluginService: AnyObject {

    func config(_ configModel: Any?)
}

public extension PluginProtocol {

    static func dependencyProtocols() -> [Any.Type]? {
        return nil
    }

    static func ignoreDependencyProtocols() -> Bool {
        return false
    }

    static func bindedEvents() -> [Event]? {
        return nil
    }
}

public final class PluginRegEntryInfo {

    public let pluginClass: AnyClass
    public let serviceType: Any.Type?
    public let serviceKey: String?
    public var options: PluginCreateOption

    public init(pluginClass: AnyClass, serviceType: Any.Type?, options: PluginCreateOption = []) {
        self.pluginClass = pluginClass
        self.serviceType = serviceType
        self.serviceKey = serviceType.map { _typeName($0, qualified: false) }
        self.options = options
    }

    public var identifier: String {
        serviceKey ?? NSStringFromClass(pluginClass)
    }
}

public final class PluginCreateGroupInfo: Hashable {

    public var createType: PluginCreateType
    public var createEvents: [Event]?

    public init(createType: PluginCreateType = .whenRegistered, createEvents: [Event]? = nil) {
        self.createType = createType
        self.createEvents = createEvents
    }

    public static func == (lhs: PluginCreateGroupInfo, rhs: PluginCreateGroupInfo) -> Bool {
        lhs.createType == rhs.createType && lhs.createEvents == rhs.createEvents
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createType.rawValue)
        hasher.combine(createEvents)
    }
}

public final class PluginRegisterSet {

    private var entries: [PluginRegEntryInfo] = []
    private var groupConfigs: [String: PluginCreateGroupInfo] = [:]
    private var defaultGroup = PluginCreateGroupInfo(createType: .whenRegistered)

    public init() {}

    public func addEntry(pluginClass: AnyClass, serviceType: Any.Type?, options: PluginCreateOption = []) {
        let entry = PluginRegEntryInfo(pluginClass: pluginClass, serviceType: serviceType, options: options)
        entries.append(entry)
    }

    public func removeEntry(serviceKey: String) {
        entries.removeAll { $0.serviceKey == serviceKey }
    }

    public func removeEntry(pluginClass: AnyClass) {
        entries.removeAll { $0.pluginClass === pluginClass }
    }

    public func configCreateType(_ createType: PluginCreateType, createEvents: [Event]? = nil, entryIDs: [String]) {
        let group = PluginCreateGroupInfo(createType: createType, createEvents: createEvents)
        for id in entryIDs {
            groupConfigs[id] = group
        }
    }

    public func allEntries() -> [PluginRegEntryInfo] {
        entries
    }

    public func createGroup(for entry: PluginRegEntryInfo) -> PluginCreateGroupInfo {
        groupConfigs[entry.identifier] ?? defaultGroup
    }

    public func allCreateGroups() -> [PluginCreateGroupInfo] {
        var groups = Set<PluginCreateGroupInfo>()
        groups.insert(defaultGroup)
        for group in groupConfigs.values {
            groups.insert(group)
        }
        return Array(groups)
    }

    public func entries(for group: PluginCreateGroupInfo) -> [PluginRegEntryInfo] {
        entries.filter { createGroup(for: $0) == group }
    }
}

@MainActor
public protocol RegisterProvider: AnyObject {

    func registerPlugins(with registerSet: PluginRegisterSet)

    func configPluginCreate(_ registerSet: PluginRegisterSet)
}

public extension RegisterProvider {

    func configPluginCreate(_ registerSet: PluginRegisterSet) {}
}
