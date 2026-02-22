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

        var key: String { String(reflecting: serviceType) }
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
    private var stickyEventBlocks: [Event: StickyEventBindBlock] = [:]

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

    /// 统一的类型 Key 生成，使用公开 API String(reflecting:)
    /// 输出格式: "PlayerKit.PlayerSpeedService"
    private static func typeKey(_ type: Any.Type) -> String {
        String(reflecting: type)
    }

    /// 统一的类 Key 生成，使用公开 API String(reflecting:)
    /// 输出格式: "PlayerKit.PlayerSpeedPlugin"
    private static func classKey(_ cls: AnyClass) -> String {
        String(reflecting: cls)
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
        // 将自己注册到 SharedContext
        (ctx as? SharedContext)?.registerContext(self)
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
        add(observer, event: event, option: [], handler: handler)
    }

    public func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        let tokens = events.compactMap { add(observer, event: $0, handler: handler) }
        return tokens.isEmpty ? nil : MultiEventHandlerToken(tokens: tokens)
    }

    public func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        let token = eventHandler.add(observer, event: event, option: option, handler: handler)
        // 触发 sticky event（在 Context 层级中查找并触发）
        triggerBindedStickyEvent(event, handler: handler)
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

        // 传播到 SharedContext，触发 sharedAdd 的监听者
        if let shared = sharedContext as? SharedContext {
            shared.receiveSharedEvent(event, object: object, senderContext: self)
        }

        extensionContexts.allObjects.forEach { $0.propagateEvent(event, object: object, sender: sender, visited: &visited) }
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
            // 同时检查类名匹配
            services.filter { Self.classKey($0.value.pluginClass) == key }.forEach {
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

    /// 绑定 Sticky 事件
    /// - Parameters:
    ///   - event: 事件名称
    ///   - bindBlock: 绑定回调，在添加监听时调用。通过设置 shouldSend 指示是否触发事件，返回事件携带的对象
    public func bindStickyEvent(_ event: Event, bindBlock: @escaping StickyEventBindBlock) {
        stickyEventBlocks[event] = bindBlock
    }

    /// 触发绑定的 Sticky 事件
    /// 在 Context 层级中查找绑定该事件的 context，执行其 bindBlock 决定是否触发
    /// - Parameters:
    ///   - event: 事件名称
    ///   - handler: 事件处理器
    /// - Returns: 是否成功触发
    @discardableResult
    private func triggerBindedStickyEvent(_ event: Event, handler: @escaping EventHandlerBlock) -> Bool {
        return _triggerBindedStickyEvent(event, handler: handler, firstContext: self)
    }

    private func _triggerBindedStickyEvent(_ event: Event, handler: @escaping EventHandlerBlock, firstContext: Context) -> Bool {
        // 先在当前 context 查找
        var didTrigger = _triggerCurrentContextBindedStickyEvent(event, handler: handler, firstContext: firstContext)

        // 如果当前 context 没有找到，继续在 subContexts 中查找
        if !didTrigger {
            for child in subContexts.allObjects {
                didTrigger = child._triggerBindedStickyEvent(event, handler: handler, firstContext: firstContext)
                if didTrigger { break }
            }
        }

        // 如果还是没有找到，继续在 baseContext 中查找
        if !didTrigger, let baseCtx = baseContext {
            didTrigger = baseCtx._triggerBindedStickyEvent(event, handler: handler, firstContext: firstContext)
        }

        return didTrigger
    }

    private func _triggerCurrentContextBindedStickyEvent(_ event: Event, handler: @escaping EventHandlerBlock, firstContext: Context) -> Bool {
        // 处理 ServiceDidLoadEvent 类型的 sticky event
        let serviceLoadPrefix = "ServiceDidLoadEvent_"
        if event.hasPrefix(serviceLoadPrefix) {
            let serviceKey = String(event.dropFirst(serviceLoadPrefix.count))
            if let entry = services[serviceKey], plugins[entry.key] != nil {
                handler(nil, event)
                return true
            }
        }

        // 处理通过 bindStickyEvent 绑定的事件
        if let bindBlock = stickyEventBlocks[event] {
            var shouldSend = false
            let eventObject = bindBlock(&shouldSend)
            if shouldSend {
                handler(eventObject, event)
                return true
            }
        }

        return false
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
                    let key = entry.serviceKey ?? Self.classKey(entry.pluginClass)
                    let clsName = Self.classKey(entry.pluginClass)

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

        if let bl = effectiveBL, bl.contains(key) || bl.contains(Self.classKey(cls)) { return }

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
        // 遍历所有绑定的 sticky event blocks，执行并决定是否重发
        for (event, bindBlock) in stickyEventBlocks {
            var shouldSend = false
            let eventObject = bindBlock(&shouldSend)
            if shouldSend {
                target.eventHandler.post(event, object: eventObject, sender: self)
            }
        }

        // 已创建的服务也是 sticky event
        for (key, entry) in services where plugins[entry.key] != nil {
            target.eventHandler.post("ServiceDidLoadEvent_\(key)", object: nil, sender: self)
        }

        subContexts.allObjects.forEach { $0.reissueStickyEvents(to: target) }
    }
}

// MARK: - SharedContext

/// 共享 Context，提供跨持有者的服务共享和事件监听能力
public final class SharedContext: SharedContextProtocol {

    // MARK: - Properties

    private let context: Context
    public var name: String? { context.name }

    /// 绑定到这个 SharedContext 的所有 Context（弱引用）
    private var boundContexts: NSHashTable<Context> = .weakObjects()

    /// 共享事件处理器
    private let sharedEventHandler = SharedEventHandler()

    /// 缓存
    private static let cache: NSMapTable<NSString, SharedContext> = .strongToWeakObjects()
    private static let lock = NSLock()

    // MARK: - Init

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

    // MARK: - SharedEventHandlerProtocol

    public func sharedAdd(_ observer: AnyObject, event: Event, handler: @escaping SharedEventHandlerBlock) -> AnyObject? {
        sharedEventHandler.add(observer, event: event, handler: handler)
    }

    // MARK: - Internal: Context Binding

    /// 注册一个 Context 到 SharedContext
    func registerContext(_ ctx: Context) {
        boundContexts.add(ctx)
    }

    /// 从 SharedContext 注销一个 Context
    func unregisterContext(_ ctx: Context) {
        boundContexts.remove(ctx)
    }

    /// 接收来自绑定 Context 的事件，分发给所有 sharedAdd 的监听者
    func receiveSharedEvent(_ event: Event, object: Any?, senderContext: PublicContext) {
        sharedEventHandler.post(event, object: object, senderContext: senderContext)
    }

    // MARK: - ServiceDiscovery

    public func resolveService<T>(_ type: T.Type) -> T? { context.resolveService(type) }
    public func tryResolveService<T>(_ type: T.Type) -> T? { context.tryResolveService(type) }
    public func resolveServiceByType(_ type: Any.Type) -> Any? { context.resolveServiceByType(type) }
    public func checkService<T>(_ type: T.Type) -> Bool { context.checkService(type) }
    public func configPlugin<T>(serviceProtocol: T.Type, withModel config: Any?) { context.configPlugin(serviceProtocol: serviceProtocol, withModel: config) }

    // MARK: - PluginRegisterProtocol

    public func unregisterService<T>(_ type: T.Type) { context.unregisterService(type) }
    public func unregisterPluginClass(_ cls: AnyClass) { context.unregisterPluginClass(cls) }
    public func batchRegister(createType: PluginCreateType, events: [Event]?, registerBlock: (PluginRegisterProtocol) -> Void) { context.batchRegister(createType: createType, events: events, registerBlock: registerBlock) }
    public func addRegProvider(_ provider: RegisterProvider) { context.addRegProvider(provider) }
    public func removeRegProvider(_ provider: RegisterProvider) { context.removeRegProvider(provider) }
    public func updateRegistryBlacklist(_ list: Set<String>?) { context.updateRegistryBlacklist(list) }
}

// MARK: - SharedEventHandler

/// 共享事件处理器，支持监听所有绑定 Context 的事件
private final class SharedEventHandler {

    private struct HandlerInfo {
        weak var observer: AnyObject?
        let event: Event
        let handler: SharedEventHandlerBlock
    }

    private var handlers: [ObjectIdentifier: HandlerInfo] = [:]
    private var nextToken: ObjectIdentifier?

    @discardableResult
    func add(_ observer: AnyObject, event: Event, handler: @escaping SharedEventHandlerBlock) -> AnyObject? {
        let token = SharedEventToken()
        handlers[ObjectIdentifier(token)] = HandlerInfo(observer: observer, event: event, handler: handler)
        return token
    }

    func post(_ event: Event, object: Any?, senderContext: PublicContext) {
        for (key, info) in handlers {
            guard info.observer != nil else {
                handlers.removeValue(forKey: key)
                continue
            }
            if info.event == event {
                info.handler(senderContext, object, event)
            }
        }
    }
}

/// 共享事件监听器 Token
private final class SharedEventToken: NSObject {}

/// 多事件处理器 Token，用于包装多个事件监听的 token
private final class MultiEventHandlerToken: NSObject {
    let tokens: [AnyObject]

    init(tokens: [AnyObject]) {
        self.tokens = tokens
        super.init()
    }
}
