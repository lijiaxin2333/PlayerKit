//
//  Context.swift
//  PlayerKit
//

import Foundation

// MARK: - Context

/// 核心 Context 实现，提供插件管理、事件分发、服务发现和层级关系管理
@MainActor
public final class Context: PublicContext, ExtendContext {

    // MARK: - ServiceEntry

    private struct ServiceEntry {
        let pluginClass: AnyClass
        let serviceType: Any.Type
        var options: PluginCreateOption
        var createType: PluginCreateType
        var configModel: Any?

        var key: String { _typeName(serviceType, qualified: false) }
    }

    // MARK: - Properties

    public weak var holder: ContextHolder?
    public private(set) var name: String?

    // 层级关系
    public private(set) weak var superContext: PublicContext?
    private var subContexts: NSHashTable<Context> = .weakObjects()

    // 扩展关系
    private weak var baseContext: Context?
    private var extensionContexts: NSHashTable<Context> = .weakObjects()

    // 共享
    private weak var sharedContext: SharedContextProtocol?

    // 服务管理
    private var services: [String: ServiceEntry] = [:]
    private var plugins: [String: BasePlugin] = [:]

    // 事件
    private let eventHandler = EventHandler()
    private var stickyEvents: [Event: Any] = [:]

    // 注册
    private var regProviders: [RegProviderEntry] = []
    private var blacklist: Set<String>?
    private var lastBlacklist: Set<String>?
    private var batchCreateType: PluginCreateType = []
    private var batchEvents: [Event]?

    private struct RegProviderEntry {
        weak var provider: (any RegisterProvider)?
        let registerSet: PluginRegisterSet
    }

    // MARK: - Init

    public init(name: String? = nil) {
        self.name = name
    }

    public convenience init(holder: ContextHolder) {
        self.init(name: String(describing: type(of: holder)))
        self.holder = holder
    }

    deinit {
        let allPlugins = Array(plugins.values)
        plugins.removeAll()
        let ctx = self
        MainActor.assumeIsolated {
            allPlugins.forEach { $0.pluginWillUnload(ctx) }
        }
    }

    public var context: ContextProtocol? { self }

    // MARK: - Type Key Helper

    private static func typeKey(_ type: Any.Type) -> String {
        _typeName(type, qualified: false)
    }

    // MARK: - SubContext

    public func addSubContext(_ child: PublicContext) {
        guard let childCtx = child as? Context else { return }
        guard childCtx.superContext === nil || childCtx.superContext === self else { return }
        guard !subContexts.contains(childCtx) else { return }

        subContexts.add(childCtx)
        childCtx.superContext = self
        childCtx.updateBlacklistHierarchy()

        childCtx.plugins.values.forEach { $0.contextDidAddToSuperContext(self) }
        plugins.values.forEach { $0.contextDidAddSubContext(childCtx) }

        childCtx.reissueStickyEvents(to: self)
    }

    public func addSubContext(_ child: PublicContext, buildBlock: ((PluginRegisterProtocol, PluginRegisterProtocol) -> Void)?) {
        addSubContext(child)
        buildBlock?(child, self)
    }

    public func removeSubContext(_ child: PublicContext) {
        (child as? Context)?.removeFromSuperContext()
    }

    public func removeFromSuperContext() {
        guard let parentCtx = superContext as? Context else { return }

        plugins.values.forEach { $0.contextWillRemoveFromSuperContext(parentCtx) }
        parentCtx.plugins.values.forEach { $0.contextWillRemoveSubContext(self) }

        parentCtx.subContexts.remove(self)
        superContext = nil
    }

    public func isDescendant(of ctx: PublicContext) -> Bool {
        self === ctx || superContext?.isDescendant(of: ctx) ?? false
    }

    public func isAncestor(of ctx: PublicContext) -> Bool {
        if self === ctx { return true }
        return subContexts.allObjects.contains { $0.isAncestor(of: ctx) }
    }

    public func bindSharedContext(_ ctx: SharedContextProtocol) {
        sharedContext = ctx
    }

    // MARK: - Extension

    public func addExtendContext(_ ext: PublicContext) {
        guard let extCtx = ext as? Context else { return }
        guard extCtx.baseContext == nil, baseContext == nil else { return }
        guard !extensionContexts.contains(extCtx) else { return }

        extensionContexts.add(extCtx)
        extCtx.baseContext = self
        extCtx.plugins.values.forEach { $0.contextDidExtend(on: self) }
    }

    public func removeExtendContext(_ ext: PublicContext) {
        guard let extCtx = ext as? Context, extCtx.baseContext === self else { return }
        extCtx.removeFromBaseContext()
    }

    public func removeFromBaseContext() {
        guard let baseCtx = baseContext else { return }
        plugins.values.forEach { $0.contextWillUnextend(on: baseCtx) }
        baseCtx.extensionContexts.remove(self)
        baseContext = nil
    }

    public func isExtension(of ctx: PublicContext) -> Bool {
        baseContext != nil && baseContext === ctx
    }

    public func isBaseContext(of ctx: PublicContext) -> Bool {
        guard let ctx = ctx as? Context else { return false }
        return extensionContexts.contains(ctx)
    }

    // MARK: - Events

    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        eventHandler.add(observer, event: event, handler: handler)
    }

    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        eventHandler.add(observer, events: events, handler: handler)
    }

    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        let token = eventHandler.add(observer, event: event, option: option, handler: handler)
        if let value = stickyEvents[event] { handler(value, event) }
        return token
    }

    public func removeHandler(_ token: AnyObject) {
        eventHandler.removeHandler(token)
    }

    public func removeHandlers(forObserver observer: AnyObject) {
        eventHandler.removeHandlers(forObserver: observer)
    }

    public func removeAllHandler() {
        eventHandler.removeAllHandler()
    }

    public func post(_ event: Event, object: Any?, sender: AnyObject) {
        var visited = Set<ObjectIdentifier>()
        propagateEvent(event, object: object, sender: sender, visited: &visited)
    }

    public func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    private func propagateEvent(_ event: Event, object: Any?, sender: AnyObject, visited: inout Set<ObjectIdentifier>) {
        let id = ObjectIdentifier(self)
        guard !visited.contains(id) else { return }
        visited.insert(id)

        eventHandler.post(event, object: object, sender: sender)

        extensionContexts.allObjects.forEach { $0.propagateEvent(event, object: object, sender: sender, visited: &visited) }
        (sharedContext as? Context)?.propagateEvent(event, object: object, sender: sender, visited: &visited)
        (superContext as? Context)?.propagateEvent(event, object: object, sender: sender, visited: &visited)
    }

    // MARK: - Service Discovery

    public func resolveService<T>(_ type: T.Type) -> T? {
        guard let service = tryResolveService(type) else {
            print("[PlayerKit] ⚠️ Service not found: \(Self.typeKey(type))")
            return nil
        }
        return service as? T
    }

    public func tryResolveService<T>(_ type: T.Type) -> T? {
        resolvePlugin(forKey: Self.typeKey(type)) as? T
    }

    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        resolvePlugin(forKey: Self.typeKey(type))
    }

    public func checkService<T>(_ type: T.Type) -> Bool {
        services[Self.typeKey(type)] != nil
    }

    public func configPlugin<T>(serviceProtocol: T.Type, withModel config: Any?) {
        let key = Self.typeKey(serviceProtocol)
        guard var entry = services[key] else {
            print("[PlayerKit] ⚠️ Service not registered: \(key)")
            return
        }

        entry.configModel = config
        services[key] = entry

        if let plugin = plugins[entry.key] {
            plugin.config(config)
        } else if entry.createType.contains(.whenFirstConfig) {
            createPlugin(from: entry)
        }
    }

    // MARK: - Plugin Registration

    public func unregisterService<T>(_ type: T.Type) {
        unregisterService(forKey: Self.typeKey(type))
    }

    public func unregisterPluginClass(_ cls: AnyClass) {
        let keys = services.filter { $0.value.pluginClass === cls }.map { $0.key }
        keys.forEach { key in
            if let entry = services[key] { removePlugin(for: entry) }
            services.removeValue(forKey: key)
        }
    }

    public func registerInstance(_ plugin: BasePlugin, protocol serviceProtocol: Any.Type) {
        let key = Self.typeKey(serviceProtocol)
        services[key] = ServiceEntry(
            pluginClass: type(of: plugin),
            serviceType: serviceProtocol,
            options: .whenRegistered,
            createType: .whenRegistered,
            configModel: nil
        )
        plugin.context = self
        plugins[key] = plugin
        plugin.pluginDidLoad(self)
    }

    public func detachInstance(for type: Any.Type) -> BasePlugin? {
        let key = Self.typeKey(type)
        guard let plugin = plugins.removeValue(forKey: key) else { return nil }
        services.removeValue(forKey: key)
        plugin.context = nil
        return plugin
    }

    // MARK: - Batch Register

    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) {
        batchCreateType = createType
        batchEvents = events
        registerBlock(self)
        batchCreateType = []
        batchEvents = nil
    }

    public func addRegProvider(_ provider: RegisterProvider) {
        guard !regProviders.contains(where: { $0.provider === provider }) else { return }

        let regSet = PluginRegisterSet()
        provider.registerPlugins(with: regSet)
        provider.configPluginCreate(regSet)

        regProviders.append(RegProviderEntry(provider: provider, registerSet: regSet))
        registerFromSet(regSet, blacklist: mergedBlacklist(blacklist), whitelist: nil)
    }

    public func removeRegProvider(_ provider: RegisterProvider) {
        guard let idx = regProviders.firstIndex(where: { $0.provider === provider }) else { return }

        let regSet = regProviders[idx].registerSet
        regSet.allEntries().forEach { entry in
            if let type = entry.serviceType {
                unregisterService(forKey: Self.typeKey(type))
            } else {
                unregisterPluginClass(entry.pluginClass)
            }
        }
        regProviders.remove(at: idx)
    }

    // MARK: - Blacklist

    public func updateRegistryBlacklist(_ list: Set<String>?) {
        blacklist = list
        updateBlacklistHierarchy()
    }

    private func mergedBlacklist(_ current: Set<String>?) -> Set<String> {
        var result = current ?? []
        var ctx = superContext as? Context
        while let c = ctx {
            if let bl = c.blacklist { result.formUnion(bl) }
            ctx = c.superContext as? Context
        }
        return result
    }

    private func updateBlacklistHierarchy() {
        let merged = mergedBlacklist(blacklist)
        let keepOld = lastBlacklist?.intersection(merged) ?? []
        let newlyBlocked = merged.subtracting(keepOld)

        for key in newlyBlocked {
            if let entry = services[key] {
                removePlugin(for: entry)
                services.removeValue(forKey: key)
            }
            services.filter { NSStringFromClass($0.value.pluginClass) == key }.forEach {
                removePlugin(for: $0.value)
                services.removeValue(forKey: $0.key)
            }
        }

        let toRestore = lastBlacklist?.subtracting(keepOld) ?? []
        if !toRestore.isEmpty {
            regProviders.forEach { entry in
                registerFromSet(entry.registerSet, blacklist: merged, whitelist: toRestore)
            }
        }

        lastBlacklist = merged
        subContexts.allObjects.forEach { $0.updateBlacklistHierarchy() }
    }

    // MARK: - Sticky Events

    public func bindStickyEvent(_ event: Event, value: Any?) {
        stickyEvents[event] = value
    }

    // MARK: - Private: Plugin Resolution

    private func resolvePlugin(forKey key: String, fromChild: Bool = false) -> BasePlugin? {
        if let entry = services[key] { return getOrCreatePlugin(from: entry) }

        for child in subContexts.allObjects {
            if let p = child.resolvePlugin(forKey: key, fromChild: true) { return p }
        }

        if !fromChild, let baseCtx = baseContext {
            return baseCtx.resolvePlugin(forKey: key, fromChild: false)
        }

        return nil
    }

    private func getOrCreatePlugin(from entry: ServiceEntry) -> BasePlugin? {
        if let p = plugins[entry.key] { return p }
        return entry.createType.contains(.whenFirstResolve) ? createPlugin(from: entry) : nil
    }

    @discardableResult
    private func createPlugin(from entry: ServiceEntry) -> BasePlugin? {
        if plugins[entry.key] != nil { return nil }

        guard let pluginType = entry.pluginClass as? BasePlugin.Type else { return nil }

        let plugin = pluginType.init()
        plugin.context = self
        if let config = entry.configModel { plugin.config(config) }

        plugins[entry.key] = plugin
        plugin.pluginDidLoad(self)

        if let p = superContext { plugin.contextDidAddToSuperContext(p) }
        subContexts.allObjects.forEach { plugin.contextDidAddSubContext($0) }
        if let b = baseContext { plugin.contextDidExtend(on: b) }

        post("ServiceDidLoadEvent_\(entry.key)", object: plugin, sender: plugin)
        return plugin
    }

    private func removePlugin(for entry: ServiceEntry) {
        if let p = plugins.removeValue(forKey: entry.key) { p.pluginWillUnload(self) }
    }

    // MARK: - Private: Registration

    private func registerFromSet(_ regSet: PluginRegisterSet, blacklist: Set<String>, whitelist: Set<String>?) {
        for group in regSet.allCreateGroups() {
            batchRegister(createType: group.createType, events: group.createEvents) { _ in
                for entry in regSet.entries(for: group) {
                    let key = entry.serviceKey ?? NSStringFromClass(entry.pluginClass)
                    let clsName = NSStringFromClass(entry.pluginClass)

                    guard !blacklist.contains(key), !blacklist.contains(clsName) else { continue }

                    if let wl = whitelist {
                        guard wl.contains(key) || wl.contains(clsName) else { continue }
                    }

                    let type = entry.serviceType ?? PluginProtocol.self
                    self.registerPlugin(entry.pluginClass, serviceType: type, options: entry.options, blacklist: blacklist)
                }
            }
        }
    }

    private func registerPlugin(_ cls: AnyClass, serviceType: Any.Type, options: PluginCreateOption, blacklist: Set<String>?) {
        let key = Self.typeKey(serviceType)
        let effectiveBL = blacklist ?? lastBlacklist ?? self.blacklist

        if let bl = effectiveBL, bl.contains(key) || bl.contains(NSStringFromClass(cls)) { return }

        var createType: PluginCreateType = options.contains(.whenRegistered) || options.isEmpty ? [.whenRegistered] : []
        createType.formUnion(batchCreateType)

        let entry = ServiceEntry(
            pluginClass: cls,
            serviceType: serviceType,
            options: options,
            createType: createType,
            configModel: nil
        )

        services[entry.key] = entry
        if createType.contains(.whenRegistered) { createPlugin(from: entry) }
    }

    private func unregisterService(forKey key: String) {
        if let entry = services[key] {
            removePlugin(for: entry)
            services.removeValue(forKey: key)
            return
        }

        subContexts.allObjects.forEach { $0.unregisterService(forKey: key) }
        baseContext?.unregisterService(forKey: key)
    }

    // MARK: - Private: Sticky Events Reissue

    private func reissueStickyEvents(to target: Context) {
        for (event, value) in stickyEvents {
            target.eventHandler.post(event, object: value, sender: self)
        }

        for (key, entry) in services where plugins[entry.key] != nil {
            target.eventHandler.post("ServiceDidLoadEvent_\(key)", object: nil, sender: self)
        }

        subContexts.allObjects.forEach { $0.reissueStickyEvents(to: target) }
    }
}

// MARK: - SharedContext

/// 共享 Context，提供跨持有者的服务共享
public final class SharedContext: SharedContextProtocol {

    private let context: Context
    public var name: String? { context.name }

    private static let cache: NSMapTable<NSString, SharedContext> = .strongToWeakObjects()
    private static let lock = NSLock()

    private init(name: String) {
        context = Context(name: "\(name)(Shared)")
    }

    public static func context(withName name: String) -> SharedContext {
        lock.lock(); defer { lock.unlock() }

        if let existing = cache.object(forKey: name as NSString) { return existing }

        let new = SharedContext(name: name)
        cache.setObject(new, forKey: name as NSString)
        return new
    }

    public func resolveService<T>(_ type: T.Type) -> T? { context.resolveService(type) }
    public func tryResolveService<T>(_ type: T.Type) -> T? { context.tryResolveService(type) }
    public func resolveServiceByType(_ type: Any.Type) -> Any? { context.resolveServiceByType(type) }
    public func checkService<T>(_ type: T.Type) -> Bool { context.checkService(type) }
    public func configPlugin<T>(serviceProtocol: T.Type, withModel config: Any?) { context.configPlugin(serviceProtocol: serviceProtocol, withModel: config) }
    public func unregisterService<T>(_ type: T.Type) { context.unregisterService(type) }
    public func unregisterPluginClass(_ cls: AnyClass) { context.unregisterPluginClass(cls) }
    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) { context.batchRegister(createType: createType, events: events, registerBlock: registerBlock) }
    public func addRegProvider(_ provider: RegisterProvider) { context.addRegProvider(provider) }
    public func removeRegProvider(_ provider: RegisterProvider) { context.removeRegProvider(provider) }
    public func updateRegistryBlacklist(_ list: Set<String>?) { context.updateRegistryBlacklist(list) }
    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? { context.add(observer, event: event, handler: handler) }
    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? { context.add(observer, events: events, handler: handler) }
    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? { context.add(observer, event: event, option: option, handler: handler) }
    public func removeHandler(_ token: AnyObject) { context.removeHandler(token) }
    public func removeHandlers(forObserver observer: AnyObject) { context.removeHandlers(forObserver: observer) }
    public func removeAllHandler() { context.removeAllHandler() }
    public func post(_ event: Event, object: Any?, sender: AnyObject) { context.post(event, object: object, sender: sender) }
    public func post(_ event: Event, sender: AnyObject) { context.post(event, sender: sender) }
}
