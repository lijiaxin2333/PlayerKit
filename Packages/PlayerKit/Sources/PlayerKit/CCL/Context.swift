//
//  Context.swift
//  playerkit
//

import Foundation

@MainActor
public final class Context: PublicContext, ExtendContext {

    private struct ServiceEntry {
        let pluginClass: AnyClass
        let protocolType: Any.Type
        let key: String
        var options: PluginCreateOption
        var createType: PluginCreateType
        var configModel: Any?

        init(pluginClass: AnyClass, protocolType: Any.Type, options: PluginCreateOption, createType: PluginCreateType, configModel: Any?) {
            self.pluginClass = pluginClass
            self.protocolType = protocolType
            self.key = _typeName(protocolType, qualified: false)
            self.options = options
            self.createType = createType
            self.configModel = configModel
        }

        func identifier() -> String {
            return key
        }
    }

    public weak var holder: ContextHolder?
    public private(set) var name: String?

    public weak private(set) var superContext: PublicContext?
    private var subContexts: NSHashTable<Context> = NSHashTable.weakObjects()

    private weak var baseContext: Context?
    private var extensionContexts: NSHashTable<Context> = NSHashTable.weakObjects()

    private weak var sharedContext: SharedContextProtocol?

    private var services: [String: ServiceEntry] = [:]
    private var pluginInstances: [String: BasePlugin] = [:]

    private let eventHandler = EventHandler()
    private var stickyEvents: [Event: Any] = [:]

    private var regProviders: [RegProviderEntry] = []
    private var registryBlacklist: Set<String>?
    private var lastUpdateBlacklist: Set<String>?

    private var batchCreateType: PluginCreateType = []
    private var batchCreateEvents: [Event]?

    private struct RegProviderEntry {
        weak var provider: (any RegisterProvider)?
        let registerSet: PluginRegisterSet
    }

    public init(name: String? = nil) {
        self.name = name
    }

    public convenience init(holder: ContextHolder) {
        self.init(name: String(describing: type(of: holder)))
        self.holder = holder
    }

    deinit {
        let allPlugins = Array(pluginInstances.values)
        pluginInstances.removeAll()

        let ctx = self
        MainActor.assumeIsolated {
            for plugin in allPlugins {
                plugin.pluginWillUnload(ctx)
            }
        }
    }

    public var context: ContextProtocol? { self }

    // MARK: - SubContext

    public func addSubContext(_ subContext: PublicContext) {
        guard let sub = subContext as? Context else { return }
        guard sub.superContext === nil || sub.superContext === self else { return }

        if subContexts.contains(sub) { return }

        subContexts.add(sub)
        sub.superContext = self

        sub._updateContextRegistryOpt()

        let subPlugins = Array(sub.pluginInstances.values)
        for plugin in subPlugins {
            plugin.contextDidAddToSuperContext(self)
        }

        let currentPlugins = Array(pluginInstances.values)
        for plugin in currentPlugins {
            plugin.contextDidAddSubContext(sub)
        }

        sub._reissueStickyEvents(to: self, shouldIterate: true)
    }

    public func addSubContext(_ subContext: PublicContext, buildBlock: ((PluginRegisterProtocol, PluginRegisterProtocol) -> Void)?) {
        addSubContext(subContext)
        buildBlock?(subContext, self)
    }

    public func removeSubContext(_ subContext: PublicContext) {
        guard let sub = subContext as? Context else { return }
        sub.removeFromSuperContext()
    }

    public func removeFromSuperContext() {
        guard let superCtx = superContext as? Context else { return }

        let currentPlugins = Array(pluginInstances.values)
        for plugin in currentPlugins {
            plugin.contextWillRemoveFromSuperContext(superCtx)
        }

        let superPlugins = Array(superCtx.pluginInstances.values)
        for plugin in superPlugins {
            plugin.contextWillRemoveSubContext(self)
        }

        superCtx.subContexts.remove(self)
        superContext = nil
    }

    public func isDescendant(of context: PublicContext) -> Bool {
        if self === context { return true }
        return superContext?.isDescendant(of: context) ?? false
    }

    public func isAncestor(of context: PublicContext) -> Bool {
        if self === context { return true }
        for sub in subContexts.allObjects {
            if sub.isAncestor(of: context) { return true }
        }
        return false
    }

    public func bindSharedContext(_ context: SharedContextProtocol) {
        sharedContext = context
    }

    // MARK: - ExtendContext

    public func addExtendContext(_ context: PublicContext) {
        guard let ext = context as? Context else { return }
        guard ext.baseContext == nil else { return }
        guard baseContext == nil else { return }
        if extensionContexts.contains(ext) { return }

        extensionContexts.add(ext)
        ext.baseContext = self

        for plugin in ext.pluginInstances.values {
            plugin.contextDidExtend(on: self)
        }
    }

    public func removeExtendContext(_ context: PublicContext) {
        guard let ext = context as? Context else { return }
        guard ext.baseContext === self else { return }
        ext.removeFromBaseContext()
    }

    public func removeFromBaseContext() {
        guard let base = baseContext else { return }

        for plugin in pluginInstances.values {
            plugin.contextWillUnextend(on: base)
        }

        base.extensionContexts.remove(self)
        baseContext = nil
    }

    public func isExtension(of context: PublicContext) -> Bool {
        return baseContext != nil && baseContext === context
    }

    public func isBaseContext(of context: PublicContext) -> Bool {
        guard let ctx = context as? Context else { return false }
        return extensionContexts.contains(ctx)
    }

    // MARK: - EventHandlerProtocol

    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, event: event, handler: handler)
    }

    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, events: events, handler: handler)
    }

    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        let token = eventHandler.add(observer, event: event, option: option, handler: handler)

        if let stickyValue = stickyEvents[event] {
            handler(stickyValue, event)
        }

        return token
    }

    public func removeHandler(_ handler: AnyObject) {
        eventHandler.removeHandler(handler)
    }

    public func removeHandlers(forObserver observer: AnyObject) {
        eventHandler.removeHandlers(forObserver: observer)
    }

    public func removeAllHandler() {
        eventHandler.removeAllHandler()
    }

    public func post(_ event: Event, object: Any?, sender: AnyObject) {
        var posted = Set<ObjectIdentifier>()
        _post(event, object: object, sender: sender, posted: &posted)
    }

    public func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    private func _post(_ event: Event, object: Any?, sender: AnyObject, posted: inout Set<ObjectIdentifier>) {
        let selfId = ObjectIdentifier(self)
        guard !posted.contains(selfId) else { return }
        posted.insert(selfId)

        eventHandler.post(event, object: object, sender: sender)

        for ext in extensionContexts.allObjects {
            ext._post(event, object: object, sender: sender, posted: &posted)
        }

        if let shared = sharedContext as? Context {
            shared._post(event, object: object, sender: sender, posted: &posted)
        }

        if let superCtx = superContext as? Context {
            superCtx._post(event, object: object, sender: sender, posted: &posted)
        }
    }

    // MARK: - ServiceDiscovery

    public func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        guard let service = tryResolveService(serviceProtocol) else {
            print("[PlayerKit] ⚠️ Service not found: \(_typeName(serviceProtocol, qualified: false))")
            return nil
        }
        return service as? T
    }

    public func tryResolveService<T>(_ serviceProtocol: T.Type) -> T? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let plugin = _resolveService(key) else {
            return nil
        }
        return plugin as? T
    }

    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        let key = _typeName(type, qualified: false)
        return _resolveService(key)
    }

    public func checkService<T>(_ serviceProtocol: T.Type) -> Bool {
        let key = _typeName(serviceProtocol, qualified: false)
        return services[key] != nil
    }

    public func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        let key = _typeName(serviceProtocol, qualified: false)

        guard var entry = services[key] else {
            print("[PlayerKit] ⚠️ Service not registered for config: \(key)")
            return
        }

        entry.configModel = configModel
        services[key] = entry

        if let plugin = pluginInstances[entry.identifier()] {
            plugin.config(configModel)
        } else if entry.createType.contains(.whenFirstConfig) {
            _createPluginInstance(for: entry)
        }
    }

    // MARK: - Internal Register

    private func _registerCls(_ pluginClass: AnyClass, protocol serviceProtocol: Any.Type, options: PluginCreateOption, blacklist: Set<String>?) {
        let effectiveBlacklist = blacklist ?? lastUpdateBlacklist ?? registryBlacklist
        let key = _typeName(serviceProtocol, qualified: false)

        if let bl = effectiveBlacklist {
            if bl.contains(key) || bl.contains(NSStringFromClass(pluginClass)) {
                return
            }
        }

        var createType: PluginCreateType = []

        if options.contains(.whenRegistered) {
            createType.insert(.whenRegistered)
        }

        if options == .none {
            createType.insert(.whenRegistered)
        }

        if !batchCreateType.isEmpty {
            createType = createType.union(batchCreateType)
        }

        let entry = ServiceEntry(
            pluginClass: pluginClass,
            protocolType: serviceProtocol,
            options: options,
            createType: createType,
            configModel: nil
        )

        let entryKey = entry.identifier()
        services[entryKey] = entry

        if entry.createType.contains(.whenRegistered) {
            _createPluginInstance(for: entry)
        }
    }

    public func unregisterService<T>(_ serviceProtocol: T.Type) {
        let key = _typeName(serviceProtocol, qualified: false)
        _unregisterServiceByKey(key)
    }

    private func _unregisterServiceByKey(_ key: String) {
        guard let entry = services[key] else {
            for sub in subContexts.allObjects {
                sub._unregisterServiceByKey(key)
            }
            if let base = baseContext {
                base._unregisterServiceByKey(key)
            }
            return
        }

        _removePluginInstance(for: entry)
        services.removeValue(forKey: key)
    }

    public func unregisterPluginClass(_ pluginClass: AnyClass) {
        let keysToRemove = services.filter { $0.value.pluginClass === pluginClass }.map { $0.key }
        for key in keysToRemove {
            if let entry = services[key] {
                _removePluginInstance(for: entry)
            }
            services.removeValue(forKey: key)
        }
    }

    // MARK: - Batch Register

    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) {
        batchCreateType = createType
        batchCreateEvents = events
        registerBlock(self)
        batchCreateType = []
        batchCreateEvents = nil
    }

    // MARK: - RegProvider

    public func addRegProvider(_ provider: RegisterProvider) {
        guard !regProviders.contains(where: { $0.provider === provider }) else { return }

        let regSet = PluginRegisterSet()
        provider.registerPlugins(with: regSet)
        provider.configPluginCreate(regSet)

        let entry = RegProviderEntry(provider: provider, registerSet: regSet)
        regProviders.append(entry)

        _batchRegister(with: regSet, blacklist: _mergedSuperContextsBlacklist(registryBlacklist), whitelist: nil)
    }

    public func removeRegProvider(_ provider: RegisterProvider) {
        guard let index = regProviders.firstIndex(where: { $0.provider === provider }) else { return }

        let regSet = regProviders[index].registerSet
        for entry in regSet.allEntries() {
            if let serviceType = entry.serviceType {
                let key = _typeName(serviceType, qualified: false)
                _unregisterServiceByKey(key)
            } else {
                unregisterPluginClass(entry.pluginClass)
            }
        }

        regProviders.remove(at: index)
    }

    // MARK: - Blacklist

    public func updateRegistryBlacklist(_ blacklist: Set<String>?) {
        registryBlacklist = blacklist
        _updateContextRegistryOpt()
    }

    private func _mergedSuperContextsBlacklist(_ currentBlacklist: Set<String>?) -> Set<String> {
        var merged = currentBlacklist ?? Set()
        var ctx = superContext as? Context
        while let c = ctx {
            if let bl = c.registryBlacklist {
                merged.formUnion(bl)
            }
            ctx = c.superContext as? Context
        }
        return merged
    }

    private func _updateContextRegistryOpt() {
        let blacklist = _mergedSuperContextsBlacklist(registryBlacklist)

        let keepBlacklist: Set<String>
        if let last = lastUpdateBlacklist {
            keepBlacklist = last.intersection(blacklist)
        } else {
            keepBlacklist = Set()
        }

        let addedBlacklist = blacklist.subtracting(keepBlacklist)

        for pluginID in addedBlacklist {
            if let entry = services[pluginID] {
                _removePluginInstance(for: entry)
                services.removeValue(forKey: pluginID)
            }
            let classKeysToRemove = services.filter { NSStringFromClass($0.value.pluginClass) == pluginID }.map { $0.key }
            for key in classKeysToRemove {
                if let entry = services[key] {
                    _removePluginInstance(for: entry)
                }
                services.removeValue(forKey: key)
            }
        }

        let restoreList: Set<String>
        if let last = lastUpdateBlacklist {
            restoreList = last.subtracting(keepBlacklist)
        } else {
            restoreList = Set()
        }

        if !restoreList.isEmpty {
            for providerEntry in regProviders {
                guard !providerEntry.registerSet.allEntries().isEmpty else { continue }
                _batchRegister(with: providerEntry.registerSet, blacklist: _mergedSuperContextsBlacklist(blacklist), whitelist: restoreList)
            }
        }

        lastUpdateBlacklist = blacklist

        for sub in subContexts.allObjects {
            sub._updateContextRegistryOpt()
        }
    }

    private func _batchRegister(with regSet: PluginRegisterSet, blacklist: Set<String>, whitelist: Set<String>?) {
        let groups = regSet.allCreateGroups()
        for group in groups {
            let entries = regSet.entries(for: group)
            batchRegister(createType: group.createType, events: group.createEvents) { ctx in
                for entry in entries {
                    let entryKey = entry.serviceKey ?? NSStringFromClass(entry.pluginClass)
                    if blacklist.contains(entryKey) || blacklist.contains(NSStringFromClass(entry.pluginClass)) {
                        continue
                    }
                    if let wl = whitelist {
                        let pluginClassName = NSStringFromClass(entry.pluginClass)
                        if !wl.contains(entryKey) && !wl.contains(pluginClassName) {
                            continue
                        }
                    }
                    if let serviceType = entry.serviceType {
                        self._registerCls(entry.pluginClass, protocol: serviceType, options: entry.options, blacklist: blacklist)
                    } else {
                        self._registerCls(entry.pluginClass, protocol: PluginProtocol.self, options: entry.options, blacklist: blacklist)
                    }
                }
            }
        }
    }

    public func registerInstance(_ plugin: BasePlugin, protocol serviceProtocol: Any.Type) {
        let key = _typeName(serviceProtocol, qualified: false)
        let entry = ServiceEntry(
            pluginClass: type(of: plugin),
            protocolType: serviceProtocol,
            options: .whenRegistered,
            createType: .whenRegistered,
            configModel: nil
        )
        services[key] = entry
        plugin.context = self
        pluginInstances[key] = plugin
        plugin.pluginDidLoad(self)
    }

    public func detachInstance(for serviceProtocol: Any.Type) -> BasePlugin? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let plugin = pluginInstances.removeValue(forKey: key) else { return nil }
        services.removeValue(forKey: key)
        plugin.context = nil
        return plugin
    }

    // MARK: - Sticky Events

    public func bindStickyEvent(_ event: Event, value: Any?) {
        stickyEvents[event] = value
    }

    // MARK: - Private Methods

    private func _resolveService(_ key: String, isSubContext: Bool = false) -> BasePlugin? {
        if let entry = services[key] {
            return _getOrCreatePlugin(for: entry)
        }

        for sub in subContexts.allObjects {
            if let plugin = sub._resolveService(key, isSubContext: true) {
                return plugin
            }
        }

        if !isSubContext, let base = baseContext {
            return base._resolveService(key, isSubContext: false)
        }

        return nil
    }

    private func _getOrCreatePlugin(for entry: ServiceEntry) -> BasePlugin? {
        let key = entry.identifier()

        if let plugin = pluginInstances[key] {
            return plugin
        }

        if entry.createType.contains(.whenFirstResolve) {
            return _createPluginInstance(for: entry)
        }

        return nil
    }

    @discardableResult
    private func _createPluginInstance(for entry: ServiceEntry) -> BasePlugin? {
        let key = entry.identifier()

        if let plugin = pluginInstances[key] {
            return plugin
        }

        guard let pluginType = entry.pluginClass as? BasePlugin.Type else {
            return nil
        }

        let plugin = pluginType.init()
        plugin.context = self

        if let config = entry.configModel {
            plugin.config(config)
        }

        pluginInstances[key] = plugin
        plugin.pluginDidLoad(self)

        if let superCtx = superContext {
            plugin.contextDidAddToSuperContext(superCtx)
        }

        for sub in subContexts.allObjects {
            plugin.contextDidAddSubContext(sub)
        }

        if let base = baseContext {
            plugin.contextDidExtend(on: base)
        }

        let eventName = "ServiceDidLoadEvent_\(entry.key)"
        post(eventName, object: plugin, sender: plugin)

        return plugin
    }

    private func _removePluginInstance(for entry: ServiceEntry) {
        let key = entry.identifier()
        if let plugin = pluginInstances.removeValue(forKey: key) {
            plugin.pluginWillUnload(self)
        }
    }

    // MARK: - Sticky Events Reissue

    private func _reissueStickyEvents(to toContext: Context, shouldIterate: Bool) {
        for (event, value) in stickyEvents {
            if shouldIterate {
                toContext._postForReissue(event, object: value)
            } else {
                toContext.eventHandler.post(event, object: value, sender: self)
            }
        }

        for (key, entry) in services {
            if pluginInstances[entry.identifier()] != nil {
                let serviceEvent = "ServiceDidLoadEvent_\(key)"
                if shouldIterate {
                    toContext._postForReissue(serviceEvent, object: nil)
                } else {
                    toContext.eventHandler.post(serviceEvent, object: nil, sender: self)
                }
            }
        }

        for sub in subContexts.allObjects {
            sub._reissueStickyEvents(to: toContext, shouldIterate: shouldIterate)
        }
    }

    private func _postForReissue(_ event: Event, object: Any?) {
        eventHandler.post(event, object: object, sender: self)
        if let superCtx = superContext as? Context {
            superCtx._postForReissue(event, object: object)
        }
        for ext in extensionContexts.allObjects {
            ext.eventHandler.post(event, object: object, sender: self)
        }
    }
}

// MARK: - SharedContext

public final class SharedContext: SharedContextProtocol {

    private var context: Context

    public var name: String? { context.name }

    private static let sharedContexts: NSMapTable<NSString, SharedContext> = NSMapTable.strongToWeakObjects()
    private static let lock = NSLock()

    private init(name: String) {
        context = Context(name: "\(name)(Shared)")
    }

    public static func context(withName name: String) -> SharedContext {
        let key = name as NSString

        lock.lock()
        defer { lock.unlock() }

        if let existing = sharedContexts.object(forKey: key) {
            return existing
        }

        let new = SharedContext(name: name)
        sharedContexts.setObject(new, forKey: key)

        return new
    }

    public func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        return context.resolveService(serviceProtocol)
    }

    public func tryResolveService<T>(_ serviceProtocol: T.Type) -> T? {
        return context.tryResolveService(serviceProtocol)
    }

    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        return context.resolveServiceByType(type)
    }

    public func checkService<T>(_ serviceProtocol: T.Type) -> Bool {
        return context.checkService(serviceProtocol)
    }

    public func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        context.configPlugin(serviceProtocol: serviceProtocol, withModel: configModel)
    }

    public func unregisterService<T>(_ serviceProtocol: T.Type) {
        context.unregisterService(serviceProtocol)
    }

    public func unregisterPluginClass(_ pluginClass: AnyClass) {
        context.unregisterPluginClass(pluginClass)
    }

    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) {
        context.batchRegister(createType: createType, events: events, registerBlock: registerBlock)
    }

    public func addRegProvider(_ provider: RegisterProvider) {
        context.addRegProvider(provider)
    }

    public func removeRegProvider(_ provider: RegisterProvider) {
        context.removeRegProvider(provider)
    }

    public func updateRegistryBlacklist(_ blacklist: Set<String>?) {
        context.updateRegistryBlacklist(blacklist)
    }

    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, event: event, handler: handler)
    }

    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, events: events, handler: handler)
    }

    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, event: event, option: option, handler: handler)
    }

    public func removeHandler(_ handler: AnyObject) {
        context.removeHandler(handler)
    }

    public func removeHandlers(forObserver observer: AnyObject) {
        context.removeHandlers(forObserver: observer)
    }

    public func removeAllHandler() {
        context.removeAllHandler()
    }

    public func post(_ event: Event, object: Any?, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    public func post(_ event: Event, sender: AnyObject) {
        context.post(event, sender: sender)
    }
}
