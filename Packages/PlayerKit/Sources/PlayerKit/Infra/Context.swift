//
//  Context.swift
//  playerkit
//

import Foundation

/** 核心 Context 实现，提供插件管理、事件分发、服务发现和层级关系管理 */
@MainActor
public final class Context: PublicContext, ExtendContext {

    /** 服务注册条目，记录插件类、协议类型、创建策略和配置模型 */
    private struct ServiceEntry {
        /** 插件类 */
        let pluginClass: AnyClass
        /** 服务协议类型 */
        let protocolType: Any.Type
        /** 插件创建选项 */
        var options: PluginCreateOption
        /** 插件创建类型 */
        var createType: PluginCreateType
        /** 配置模型 */
        var configModel: Any?

        /** 服务标识键，从协议类型自动推断 */
        var key: String {
            _typeName(protocolType, qualified: false)
        }

        /** 初始化服务条目 */
        init(pluginClass: AnyClass, protocolType: Any.Type, options: PluginCreateOption, createType: PluginCreateType, configModel: Any?) {
            self.pluginClass = pluginClass
            self.protocolType = protocolType
            self.options = options
            self.createType = createType
            self.configModel = configModel
        }
    }

    /** Context 的持有者弱引用 */
    public weak var holder: ContextHolder?
    /** Context 的名称标识 */
    public private(set) var name: String?

    /** 父级 Context 弱引用 */
    public weak private(set) var superContext: PublicContext?
    /** 子 Context 集合，使用弱引用哈希表 */
    private var subContexts: NSHashTable<Context> = NSHashTable.weakObjects()

    /** 基础 Context 弱引用（扩展关系） */
    private weak var baseContext: Context?
    /** 扩展 Context 集合，使用弱引用哈希表 */
    private var extensionContexts: NSHashTable<Context> = NSHashTable.weakObjects()

    /** 共享 Context 弱引用 */
    private weak var sharedContext: SharedContextProtocol?

    /** 已注册的服务条目映射 */
    private var services: [String: ServiceEntry] = [:]
    /** 已创建的插件实例映射 */
    private var pluginInstances: [String: BasePlugin] = [:]

    /** 事件处理器 */
    private let eventHandler = EventHandler()
    /** 粘性事件存储 */
    private var stickyEvents: [Event: Any] = [:]

    /** 注册提供者列表 */
    private var regProviders: [RegProviderEntry] = []
    /** 注册黑名单 */
    private var registryBlacklist: Set<String>?
    /** 上次更新的黑名单快照 */
    private var lastUpdateBlacklist: Set<String>?

    /** 批量注册时的创建类型 */
    private var batchCreateType: PluginCreateType = []
    /** 批量注册时的触发事件 */
    private var batchCreateEvents: [Event]?

    /** 注册提供者条目，保存提供者弱引用和对应的注册集合 */
    private struct RegProviderEntry {
        /** 注册提供者弱引用 */
        weak var provider: (any RegisterProvider)?
        /** 注册集合 */
        let registerSet: PluginRegisterSet
    }

    /** 初始化 Context，可指定名称 */
    public init(name: String? = nil) {
        self.name = name
    }

    /** 便利初始化，使用持有者类名作为 Context 名称 */
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

    /** 返回自身作为 ContextProtocol */
    public var context: ContextProtocol? { self }

    // MARK: - SubContext

    /** 添加子 Context，建立父子层级关系并触发相关生命周期回调 */
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

    /** 添加子 Context 并执行构建闭包 */
    public func addSubContext(_ subContext: PublicContext, buildBlock: ((PluginRegisterProtocol, PluginRegisterProtocol) -> Void)?) {
        addSubContext(subContext)
        buildBlock?(subContext, self)
    }

    /** 移除子 Context */
    public func removeSubContext(_ subContext: PublicContext) {
        guard let sub = subContext as? Context else { return }
        sub.removeFromSuperContext()
    }

    /** 从父 Context 中移除自身，并触发相关生命周期回调 */
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

    /** 判断当前 Context 是否是指定 Context 的后代（递归向上查找） */
    public func isDescendant(of context: PublicContext) -> Bool {
        if self === context { return true }
        return superContext?.isDescendant(of: context) ?? false
    }

    /** 判断当前 Context 是否是指定 Context 的祖先（递归向下查找） */
    public func isAncestor(of context: PublicContext) -> Bool {
        if self === context { return true }
        for sub in subContexts.allObjects {
            if sub.isAncestor(of: context) { return true }
        }
        return false
    }

    /** 绑定共享 Context */
    public func bindSharedContext(_ context: SharedContextProtocol) {
        sharedContext = context
    }

    // MARK: - ExtendContext

    /** 添加扩展 Context，建立扩展关系并触发回调 */
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

    /** 移除扩展 Context */
    public func removeExtendContext(_ context: PublicContext) {
        guard let ext = context as? Context else { return }
        guard ext.baseContext === self else { return }
        ext.removeFromBaseContext()
    }

    /** 从基础 Context 中移除自身的扩展关系 */
    public func removeFromBaseContext() {
        guard let base = baseContext else { return }

        for plugin in pluginInstances.values {
            plugin.contextWillUnextend(on: base)
        }

        base.extensionContexts.remove(self)
        baseContext = nil
    }

    /** 判断当前 Context 是否是指定 Context 的扩展 */
    public func isExtension(of context: PublicContext) -> Bool {
        return baseContext != nil && baseContext === context
    }

    /** 判断当前 Context 是否是指定 Context 的基础 */
    public func isBaseContext(of context: PublicContext) -> Bool {
        guard let ctx = context as? Context else { return false }
        return extensionContexts.contains(ctx)
    }

    // MARK: - EventHandlerProtocol

    /** 添加单个事件的监听器 */
    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, event: event, handler: handler)
    }

    /** 添加多个事件的监听器 */
    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        return eventHandler.add(observer, events: events, handler: handler)
    }

    /** 添加带选项的事件监听器，支持粘性事件回放 */
    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        let token = eventHandler.add(observer, event: event, option: option, handler: handler)

        if let stickyValue = stickyEvents[event] {
            handler(stickyValue, event)
        }

        return token
    }

    /** 通过 token 移除指定事件处理器 */
    public func removeHandler(_ handler: AnyObject) {
        eventHandler.removeHandler(handler)
    }

    /** 移除指定观察者的所有事件处理器 */
    public func removeHandlers(forObserver observer: AnyObject) {
        eventHandler.removeHandlers(forObserver: observer)
    }

    /** 移除所有事件处理器 */
    public func removeAllHandler() {
        eventHandler.removeAllHandler()
    }

    /** 发送事件，沿 Context 层级向上传播（扩展 → 共享 → 父级） */
    public func post(_ event: Event, object: Any?, sender: AnyObject) {
        var posted = Set<ObjectIdentifier>()
        _post(event, object: object, sender: sender, posted: &posted)
    }

    /** 发送事件，不携带附加数据 */
    public func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    /** 内部事件发送实现，防止循环发送并沿层级传播 */
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

    /** 解析服务实例，未找到时打印警告 */
    public func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        guard let service = tryResolveService(serviceProtocol) else {
            print("[PlayerKit] ⚠️ Service not found: \(_typeName(serviceProtocol, qualified: false))")
            return nil
        }
        return service as? T
    }

    /** 尝试解析服务实例，未找到时静默返回 nil */
    public func tryResolveService<T>(_ serviceProtocol: T.Type) -> T? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let plugin = _resolveService(key) else {
            return nil
        }
        return plugin as? T
    }

    /** 通过类型解析服务实例 */
    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        let key = _typeName(type, qualified: false)
        return _resolveService(key)
    }

    /** 检查指定服务是否已注册 */
    public func checkService<T>(_ serviceProtocol: T.Type) -> Bool {
        let key = _typeName(serviceProtocol, qualified: false)
        return services[key] != nil
    }

    /** 配置指定服务协议对应的插件，若插件未创建且创建类型为首次配置则触发创建 */
    public func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        let key = _typeName(serviceProtocol, qualified: false)

        guard var entry = services[key] else {
            print("[PlayerKit] ⚠️ Service not registered for config: \(key)")
            return
        }

        entry.configModel = configModel
        services[key] = entry

        if let plugin = pluginInstances[entry.key] {
            plugin.config(configModel)
        } else if entry.createType.contains(.whenFirstConfig) {
            _createPluginInstance(for: entry)
        }
    }

    // MARK: - Internal Register

    /** 注册插件类到指定服务协议，支持黑名单过滤和批量创建类型 */
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

        let entryKey = entry.key
        services[entryKey] = entry

        if entry.createType.contains(.whenRegistered) {
            _createPluginInstance(for: entry)
        }
    }

    /** 注销指定服务协议对应的插件 */
    public func unregisterService<T>(_ serviceProtocol: T.Type) {
        let key = _typeName(serviceProtocol, qualified: false)
        _unregisterServiceByKey(key)
    }

    /** 按 key 注销服务，递归搜索子 Context 和基础 Context */
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

    /** 注销指定类的所有插件 */
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

    /** 批量注册插件，临时设置创建类型和触发事件 */
    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) {
        batchCreateType = createType
        batchCreateEvents = events
        registerBlock(self)
        batchCreateType = []
        batchCreateEvents = nil
    }

    // MARK: - RegProvider

    /** 添加注册提供者，执行其注册逻辑并创建插件 */
    public func addRegProvider(_ provider: RegisterProvider) {
        guard !regProviders.contains(where: { $0.provider === provider }) else { return }

        let regSet = PluginRegisterSet()
        provider.registerPlugins(with: regSet)
        provider.configPluginCreate(regSet)

        let entry = RegProviderEntry(provider: provider, registerSet: regSet)
        regProviders.append(entry)

        _batchRegister(with: regSet, blacklist: _mergedSuperContextsBlacklist(registryBlacklist), whitelist: nil)
    }

    /** 移除注册提供者并注销其注册的所有插件 */
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

    /** 更新注册黑名单，触发已注册插件的清理和恢复 */
    public func updateRegistryBlacklist(_ blacklist: Set<String>?) {
        registryBlacklist = blacklist
        _updateContextRegistryOpt()
    }

    /** 合并当前及所有祖先 Context 的黑名单 */
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

    /** 更新注册黑名单状态，移除黑名单中的插件并恢复白名单中的插件 */
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

    /** 使用注册集合批量注册插件，支持黑名单过滤和白名单恢复 */
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

    /** 注册已有的插件实例到指定服务协议 */
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

    /** 分离指定服务协议对应的插件实例，返回被分离的插件 */
    public func detachInstance(for serviceProtocol: Any.Type) -> BasePlugin? {
        let key = _typeName(serviceProtocol, qualified: false)
        guard let plugin = pluginInstances.removeValue(forKey: key) else { return nil }
        services.removeValue(forKey: key)
        plugin.context = nil
        return plugin
    }

    // MARK: - Sticky Events

    /** 绑定粘性事件值，后续注册的监听者会立即收到该值 */
    public func bindStickyEvent(_ event: Event, value: Any?) {
        stickyEvents[event] = value
    }

    // MARK: - Private Methods

    /** 按 key 解析服务实例，依次搜索当前 → 子 Context → 基础 Context */
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

    /** 获取或按需创建插件实例 */
    private func _getOrCreatePlugin(for entry: ServiceEntry) -> BasePlugin? {
        let key = entry.key

        if let plugin = pluginInstances[key] {
            return plugin
        }

        if entry.createType.contains(.whenFirstResolve) {
            return _createPluginInstance(for: entry)
        }

        return nil
    }

    /** 创建插件实例，执行加载回调并发送服务加载事件 */
    @discardableResult
    private func _createPluginInstance(for entry: ServiceEntry) -> BasePlugin? {
        let key = entry.key

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

    /** 移除插件实例并触发卸载回调 */
    private func _removePluginInstance(for entry: ServiceEntry) {
        let key = entry.key
        if let plugin = pluginInstances.removeValue(forKey: key) {
            plugin.pluginWillUnload(self)
        }
    }

    // MARK: - Sticky Events Reissue

    /** 向目标 Context 重新发送粘性事件，用于子 Context 添加到父 Context 时的事件同步 */
    private func _reissueStickyEvents(to toContext: Context, shouldIterate: Bool) {
        for (event, value) in stickyEvents {
            if shouldIterate {
                toContext._postForReissue(event, object: value)
            } else {
                toContext.eventHandler.post(event, object: value, sender: self)
            }
        }

        for (key, entry) in services {
            if pluginInstances[entry.key] != nil {
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

    /** 用于粘性事件重发的内部发送方法，沿层级向上传播 */
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

/** 共享 Context，提供跨多个持有者的服务共享，使用弱引用缓存 */
public final class SharedContext: SharedContextProtocol {

    /** 内部持有的 Context 实例 */
    private var context: Context

    /** 共享 Context 的名称 */
    public var name: String? { context.name }

    /** 全局共享 Context 缓存，使用弱引用防止泄漏 */
    private static let sharedContexts: NSMapTable<NSString, SharedContext> = NSMapTable.strongToWeakObjects()
    /** 线程安全锁 */
    private static let lock = NSLock()

    /** 初始化共享 Context */
    private init(name: String) {
        context = Context(name: "\(name)(Shared)")
    }

    /** 获取或创建指定名称的共享 Context */
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

    /** 解析服务实例，委托给内部 Context */
    public func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        return context.resolveService(serviceProtocol)
    }

    /** 尝试解析服务实例，委托给内部 Context */
    public func tryResolveService<T>(_ serviceProtocol: T.Type) -> T? {
        return context.tryResolveService(serviceProtocol)
    }

    /** 通过类型解析服务实例，委托给内部 Context */
    public func resolveServiceByType(_ type: Any.Type) -> Any? {
        return context.resolveServiceByType(type)
    }

    /** 检查服务是否已注册，委托给内部 Context */
    public func checkService<T>(_ serviceProtocol: T.Type) -> Bool {
        return context.checkService(serviceProtocol)
    }

    /** 配置插件，委托给内部 Context */
    public func configPlugin<T>(serviceProtocol: T.Type, withModel configModel: Any?) {
        context.configPlugin(serviceProtocol: serviceProtocol, withModel: configModel)
    }

    /** 注销服务，委托给内部 Context */
    public func unregisterService<T>(_ serviceProtocol: T.Type) {
        context.unregisterService(serviceProtocol)
    }

    /** 注销插件类，委托给内部 Context */
    public func unregisterPluginClass(_ pluginClass: AnyClass) {
        context.unregisterPluginClass(pluginClass)
    }

    /** 批量注册，委托给内部 Context */
    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) {
        context.batchRegister(createType: createType, events: events, registerBlock: registerBlock)
    }

    /** 添加注册提供者，委托给内部 Context */
    public func addRegProvider(_ provider: RegisterProvider) {
        context.addRegProvider(provider)
    }

    /** 移除注册提供者，委托给内部 Context */
    public func removeRegProvider(_ provider: RegisterProvider) {
        context.removeRegProvider(provider)
    }

    /** 更新注册黑名单，委托给内部 Context */
    public func updateRegistryBlacklist(_ blacklist: Set<String>?) {
        context.updateRegistryBlacklist(blacklist)
    }

    /** 添加单事件监听器，委托给内部 Context */
    public func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, event: event, handler: handler)
    }

    /** 添加多事件监听器，委托给内部 Context */
    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, events: events, handler: handler)
    }

    /** 添加带选项的事件监听器，委托给内部 Context */
    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return context.add(observer, event: event, option: option, handler: handler)
    }

    /** 移除指定事件处理器，委托给内部 Context */
    public func removeHandler(_ handler: AnyObject) {
        context.removeHandler(handler)
    }

    /** 移除指定观察者的所有处理器，委托给内部 Context */
    public func removeHandlers(forObserver observer: AnyObject) {
        context.removeHandlers(forObserver: observer)
    }

    /** 移除所有处理器，委托给内部 Context */
    public func removeAllHandler() {
        context.removeAllHandler()
    }

    /** 发送事件（携带数据），委托给内部 Context */
    public func post(_ event: Event, object: Any?, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    /** 发送事件（不携带数据），委托给内部 Context */
    public func post(_ event: Event, sender: AnyObject) {
        context.post(event, sender: sender)
    }
}
