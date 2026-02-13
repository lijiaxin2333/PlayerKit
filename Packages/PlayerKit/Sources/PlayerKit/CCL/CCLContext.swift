//
//  CCLContext.swift
//  playerkit
//
//  CCL Context 实现
//

import Foundation

// MARK: - CCL Context

@MainActor
public final class CCLContext: CCLPublicContext, CCLExtendContext {

    // MARK: - Nested Types

    private struct ServiceEntry {
        let compClass: AnyClass
        let protocolType: Any.Type
        let key: String
        var options: CCLCompCreateOption
        var createType: CCLCompCreateType
        var configModel: Any?

        init(compClass: AnyClass, protocolType: Any.Type, options: CCLCompCreateOption, createType: CCLCompCreateType, configModel: Any?) {
            self.compClass = compClass
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

    // MARK: - Properties

    public weak var holder: CCLContextHolder?
    public private(set) var name: String?

    public weak private(set) var superContext: CCLPublicContext?
    private var subContexts: NSHashTable<CCLContext> = NSHashTable.weakObjects()

    private weak var baseContext: CCLContext?
    private var extensionContexts: NSHashTable<CCLContext> = NSHashTable.weakObjects()

    private weak var sharedContext: CCLSharedContextProtocol?

    private var services: [String: ServiceEntry] = [:]
    private var compInstances: [String: CCLBaseComp] = [:]

    private let eventHandler = CCLEventHandler()
    private var stickyEvents: [CCLEvent: Any] = [:]

    private var regProviders: [RegProviderEntry] = []
    private var registryBlacklist: Set<String>?
    private var lastUpdateBlacklist: Set<String>?

    private var batchCreateType: CCLCompCreateType = []
    private var batchCreateEvents: [CCLEvent]?

    private struct RegProviderEntry {
        weak var provider: (any CCLRegisterProvider)?
        let registerSet: CCLCompRegisterSet
    }

    // MARK: - Initialization

    public init(name: String? = nil) {
        self.name = name
    }

    public convenience init(holder: CCLContextHolder) {
        self.init(name: String(describing: type(of: holder)))
        self.holder = holder
    }

    deinit {
        let allComps = Array(compInstances.values)
        compInstances.removeAll()

        let ctx = self
        MainActor.assumeIsolated {
            for comp in allComps {
                comp.componentWillUnload(ctx)
            }
        }
    }

    // MARK: - CCLContextProtocol

    public var context: CCLContextProtocol? { self }

    // MARK: - CCLPublicContext - SubContext 管理

    public func addSubContext(_ subContext: CCLPublicContext) {
        guard let sub = subContext as? CCLContext else { return }
        guard sub.superContext === nil || sub.superContext === self else { return }

        if subContexts.contains(sub) { return }

        subContexts.add(sub)
        sub.superContext = self

        sub._updateContextRegistryOpt()

        let subComps = Array(sub.compInstances.values)
        for comp in subComps {
            comp.contextDidAddToSuperContext(self)
        }

        let currentComps = Array(compInstances.values)
        for comp in currentComps {
            comp.contextDidAddSubContext(sub)
        }

        sub._reissueStickyEvents(to: self, shouldIterate: true)
    }

    public func addSubContext(_ subContext: CCLPublicContext, buildBlock: ((CCLCompRegisterProtocol, CCLCompRegisterProtocol) -> Void)?) {
        addSubContext(subContext)
        buildBlock?(subContext, self)
    }

    public func removeSubContext(_ subContext: CCLPublicContext) {
        guard let sub = subContext as? CCLContext else { return }
        sub.removeFromSuperContext()
    }

    public func removeFromSuperContext() {
        guard let superCtx = superContext as? CCLContext else { return }

        let currentComps = Array(compInstances.values)
        for comp in currentComps {
            comp.contextWillRemoveFromSuperContext(superCtx)
        }

        let superComps = Array(superCtx.compInstances.values)
        for comp in superComps {
            comp.contextWillRemoveSubContext(self)
        }

        superCtx.subContexts.remove(self)
        superContext = nil
    }

    public func isDescendant(of context: CCLPublicContext) -> Bool {
        if self === context { return true }
        return superContext?.isDescendant(of: context) ?? false
    }

    public func isAncestor(of context: CCLPublicContext) -> Bool {
        if self === context { return true }
        for sub in subContexts.allObjects {
            if sub.isAncestor(of: context) { return true }
        }
        return false
    }

    public func bindSharedContext(_ context: CCLSharedContextProtocol) {
        sharedContext = context
    }

    // MARK: - CCLExtendContext

    public func addExtendContext(_ context: CCLPublicContext) {
        guard let ext = context as? CCLContext else { return }
        guard ext.baseContext == nil else { return }
        guard baseContext == nil else { return }
        if extensionContexts.contains(ext) { return }

        extensionContexts.add(ext)
        ext.baseContext = self

        for comp in ext.compInstances.values {
            comp.contextDidExtend(on: self)
        }
    }

    public func removeExtendContext(_ context: CCLPublicContext) {
        guard let ext = context as? CCLContext else { return }
        guard ext.baseContext === self else { return }
        ext.removeFromBaseContext()
    }

    public func removeFromBaseContext() {
        guard let base = baseContext else { return }

        for comp in compInstances.values {
            comp.contextWillUnextend(on: base)
        }

        base.extensionContexts.remove(self)
        baseContext = nil
    }

    public func isExtension(of context: CCLPublicContext) -> Bool {
        return baseContext != nil && baseContext === context
    }

    public func isBaseContext(of context: CCLPublicContext) -> Bool {
        guard let ctx = context as? CCLContext else { return false }
        return extensionContexts.contains(ctx)
    }

    // MARK: - CCLEventHandlerProtocol

    public func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, event: event, handler: handler)
    }

    public func add(_ observer: AnyObject, events: [CCLEvent], handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, events: events, handler: handler)
    }

    public func add(_ observer: AnyObject, event: CCLEvent, option: CCLEventOption, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        let token = eventHandler.add(observer, event: event, option: option, handler: handler)

        // 检查是否有粘性事件
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

    public func post(_ event: CCLEvent, object: Any?, sender: AnyObject) {
        var posted = Set<ObjectIdentifier>()
        _post(event, object: object, sender: sender, posted: &posted)
    }

    public func post(_ event: CCLEvent, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    private func _post(_ event: CCLEvent, object: Any?, sender: AnyObject, posted: inout Set<ObjectIdentifier>) {
        let selfId = ObjectIdentifier(self)
        guard !posted.contains(selfId) else { return }
        posted.insert(selfId)

        eventHandler.post(event, object: object, sender: sender)

        for ext in extensionContexts.allObjects {
            ext._post(event, object: object, sender: sender, posted: &posted)
        }

        if let shared = sharedContext as? CCLContext {
            shared._post(event, object: object, sender: sender, posted: &posted)
        }

        if let superCtx = superContext as? CCLContext {
            superCtx._post(event, object: object, sender: sender, posted: &posted)
        }
    }

    // MARK: - CCLServiceDiscovery (通过协议类型)

    public func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        guard let service = tryResolveService(serviceProtocol) else {
            print("[CCL] ⚠️ Service not found: \(_typeName(serviceProtocol, qualified: false))")
            return nil
        }
        return service as? T
    }

    public func tryResolveService<T>(_ serviceProtocol: T.Type) -> T? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let comp = _resolveService(key) else {
            return nil
        }
        return comp as? T
    }

    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        let key = _typeName(type, qualified: false)
        return _resolveService(key)
    }

    public func checkService<T>(_ serviceProtocol: T.Type) -> Bool {
        let key = _typeName(serviceProtocol, qualified: false)
        return services[key] != nil
    }

    public func configComp<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        let key = _typeName(serviceProtocol, qualified: false)

        guard var entry = services[key] else {
            print("[CCL] ⚠️ Service not registered for config: \(key)")
            return
        }

        entry.configModel = configModel
        services[key] = entry

        // 如果组件已创建，直接配置
        if let comp = compInstances[entry.identifier()] {
            comp.config(configModel)
        } else if entry.createType.contains(.whenFirstConfig) {
            // 延迟创建
            _createCompInstance(for: entry)
        }
    }

    // MARK: - Internal Register

    private func _registerCls(_ compClass: AnyClass, protocol serviceProtocol: Any.Type, options: CCLCompCreateOption, blacklist: Set<String>?) {
        let effectiveBlacklist = blacklist ?? lastUpdateBlacklist ?? registryBlacklist
        let key = _typeName(serviceProtocol, qualified: false)

        if let bl = effectiveBlacklist {
            if bl.contains(key) || bl.contains(NSStringFromClass(compClass)) {
                return
            }
        }

        var createType: CCLCompCreateType = []

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
            compClass: compClass,
            protocolType: serviceProtocol,
            options: options,
            createType: createType,
            configModel: nil
        )

        let entryKey = entry.identifier()
        services[entryKey] = entry

        if entry.createType.contains(.whenRegistered) {
            _createCompInstance(for: entry)
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

        _removeCompInstance(for: entry)
        services.removeValue(forKey: key)
    }

    public func unregisterCompClass(_ compClass: AnyClass) {
        let keysToRemove = services.filter { $0.value.compClass === compClass }.map { $0.key }
        for key in keysToRemove {
            if let entry = services[key] {
                _removeCompInstance(for: entry)
            }
            services.removeValue(forKey: key)
        }
    }

    // MARK: - Batch Register

    public func batchRegister(createType: CCLCompCreateType, events: [CCLEvent]?, registerBlock: (CCLCompRegisterProtocol) -> Void) {
        batchCreateType = createType
        batchCreateEvents = events
        registerBlock(self)
        batchCreateType = []
        batchCreateEvents = nil
    }

    // MARK: - RegProvider

    public func addRegProvider(_ provider: CCLRegisterProvider) {
        guard !regProviders.contains(where: { $0.provider === provider }) else { return }

        let regSet = CCLCompRegisterSet()
        provider.registerComps(with: regSet)
        provider.configCompCreate(regSet)

        let entry = RegProviderEntry(provider: provider, registerSet: regSet)
        regProviders.append(entry)

        _batchRegister(with: regSet, blacklist: _mergedSuperContextsBlacklist(registryBlacklist), whitelist: nil)
    }

    public func removeRegProvider(_ provider: CCLRegisterProvider) {
        guard let index = regProviders.firstIndex(where: { $0.provider === provider }) else { return }

        let regSet = regProviders[index].registerSet
        for entry in regSet.allEntries() {
            if let serviceType = entry.serviceType {
                let key = _typeName(serviceType, qualified: false)
                _unregisterServiceByKey(key)
            } else {
                unregisterCompClass(entry.compClass)
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
        var ctx = superContext as? CCLContext
        while let c = ctx {
            if let bl = c.registryBlacklist {
                merged.formUnion(bl)
            }
            ctx = c.superContext as? CCLContext
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

        for compID in addedBlacklist {
            if let entry = services[compID] {
                _removeCompInstance(for: entry)
                services.removeValue(forKey: compID)
            }
            let classKeysToRemove = services.filter { NSStringFromClass($0.value.compClass) == compID }.map { $0.key }
            for key in classKeysToRemove {
                if let entry = services[key] {
                    _removeCompInstance(for: entry)
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

    private func _batchRegister(with regSet: CCLCompRegisterSet, blacklist: Set<String>, whitelist: Set<String>?) {
        let groups = regSet.allCreateGroups()
        for group in groups {
            let entries = regSet.entries(for: group)
            batchRegister(createType: group.createType, events: group.createEvents) { ctx in
                for entry in entries {
                    let entryKey = entry.serviceKey ?? NSStringFromClass(entry.compClass)
                    if blacklist.contains(entryKey) || blacklist.contains(NSStringFromClass(entry.compClass)) {
                        continue
                    }
                    if let wl = whitelist {
                        let compClassName = NSStringFromClass(entry.compClass)
                        if !wl.contains(entryKey) && !wl.contains(compClassName) {
                            continue
                        }
                    }
                    if let serviceType = entry.serviceType {
                        self._registerCls(entry.compClass, protocol: serviceType, options: entry.options, blacklist: blacklist)
                    } else {
                        self._registerCls(entry.compClass, protocol: CCLCompProtocol.self, options: entry.options, blacklist: blacklist)
                    }
                }
            }
        }
    }

    public func registerInstance(_ comp: CCLBaseComp, protocol serviceProtocol: Any.Type) {
        let key = _typeName(serviceProtocol, qualified: false)
        let entry = ServiceEntry(
            compClass: type(of: comp),
            protocolType: serviceProtocol,
            options: .whenRegistered,
            createType: .whenRegistered,
            configModel: nil
        )
        services[key] = entry
        comp.context = self
        compInstances[key] = comp
        comp.componentDidLoad(self)
    }

    public func detachInstance(for serviceProtocol: Any.Type) -> CCLBaseComp? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let comp = compInstances.removeValue(forKey: key) else { return nil }
        services.removeValue(forKey: key)
        comp.context = nil
        return comp
    }

    // MARK: - Sticky Events

    public func bindStickyEvent(_ event: CCLEvent, value: Any?) {
        stickyEvents[event] = value
    }

    // MARK: - Private Methods

    private func _resolveService(_ key: String, isSubContext: Bool = false) -> CCLBaseComp? {
        if let entry = services[key] {
            return _getOrCreateComp(for: entry)
        }

        for sub in subContexts.allObjects {
            if let comp = sub._resolveService(key, isSubContext: true) {
                return comp
            }
        }

        if !isSubContext, let base = baseContext {
            return base._resolveService(key, isSubContext: false)
        }

        return nil
    }

    private func _getOrCreateComp(for entry: ServiceEntry) -> CCLBaseComp? {
        let key = entry.identifier()

        if let comp = compInstances[key] {
            return comp
        }

        if entry.createType.contains(.whenFirstResolve) {
            return _createCompInstance(for: entry)
        }

        return nil
    }

    @discardableResult
    private func _createCompInstance(for entry: ServiceEntry) -> CCLBaseComp? {
        let key = entry.identifier()

        if let comp = compInstances[key] {
            return comp
        }

        guard let compType = entry.compClass as? CCLBaseComp.Type else {
            return nil
        }

        let comp = compType.init()
        comp.context = self

        if let config = entry.configModel {
            comp.config(config)
        }

        compInstances[key] = comp
        comp.componentDidLoad(self)

        if let superCtx = superContext {
            comp.contextDidAddToSuperContext(superCtx)
        }

        for sub in subContexts.allObjects {
            comp.contextDidAddSubContext(sub)
        }

        if let base = baseContext {
            comp.contextDidExtend(on: base)
        }

        let eventName = "CCLServiceDidLoadEvent_\(entry.key)"
        post(eventName, object: comp, sender: comp)

        return comp
    }

    private func _removeCompInstance(for entry: ServiceEntry) {
        let key = entry.identifier()
        if let comp = compInstances.removeValue(forKey: key) {
            comp.componentWillUnload(self)
        }
    }

    // MARK: - Sticky Events Reissue

    private func _reissueStickyEvents(to toContext: CCLContext, shouldIterate: Bool) {
        for (event, value) in stickyEvents {
            if shouldIterate {
                toContext._postForReissue(event, object: value)
            } else {
                toContext.eventHandler.post(event, object: value, sender: self)
            }
        }

        for (key, entry) in services {
            if compInstances[entry.identifier()] != nil {
                let serviceEvent = "CCLServiceDidLoadEvent_\(key)"
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

    private func _postForReissue(_ event: CCLEvent, object: Any?) {
        eventHandler.post(event, object: object, sender: self)
        if let superCtx = superContext as? CCLContext {
            superCtx._postForReissue(event, object: object)
        }
        for ext in extensionContexts.allObjects {
            ext.eventHandler.post(event, object: object, sender: self)
        }
    }
}

// MARK: - CCL 共享 Context

public final class CCLSharedContext: CCLSharedContextProtocol {

    private var context: CCLContext

    public var name: String? { context.name }

    private static let sharedContexts: NSMapTable<NSString, CCLSharedContext> = NSMapTable.strongToWeakObjects()
    private static let lock = NSLock()

    private init(name: String) {
        context = CCLContext(name: "\(name)(Shared)")
    }

    public static func context(withName name: String) -> CCLSharedContext {
        let key = name as NSString

        lock.lock()
        defer { lock.unlock() }

        if let existing = sharedContexts.object(forKey: key) {
            return existing
        }

        let new = CCLSharedContext(name: name)
        sharedContexts.setObject(new, forKey: key)

        return new
    }

    // MARK: - CCLServiceDiscovery

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

    public func configComp<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        context.configComp(serviceProtocol: serviceProtocol, withModel: configModel)
    }

    // MARK: - CCLCompRegisterProtocol

    public func unregisterService<T>(_ serviceProtocol: T.Type) {
        context.unregisterService(serviceProtocol)
    }

    public func unregisterCompClass(_ compClass: AnyClass) {
        context.unregisterCompClass(compClass)
    }

    public func batchRegister(createType: CCLCompCreateType, events: [CCLEvent]?, registerBlock: (CCLCompRegisterProtocol) -> Void) {
        context.batchRegister(createType: createType, events: events, registerBlock: registerBlock)
    }

    public func addRegProvider(_ provider: CCLRegisterProvider) {
        context.addRegProvider(provider)
    }

    public func removeRegProvider(_ provider: CCLRegisterProvider) {
        context.removeRegProvider(provider)
    }

    public func updateRegistryBlacklist(_ blacklist: Set<String>?) {
        context.updateRegistryBlacklist(blacklist)
    }

    // MARK: - CCLEventHandlerProtocol

    public func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        return context.add(observer, event: event, handler: handler)
    }

    public func add(_ observer: AnyObject, events: [CCLEvent], handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        return context.add(observer, events: events, handler: handler)
    }

    public func add(_ observer: AnyObject, event: CCLEvent, option: CCLEventOption, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
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

    public func post(_ event: CCLEvent, object: Any?, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    public func post(_ event: CCLEvent, sender: AnyObject) {
        context.post(event, sender: sender)
    }
}
