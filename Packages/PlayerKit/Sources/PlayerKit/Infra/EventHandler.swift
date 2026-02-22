//
//  EventHandler.swift
//  PlayerKit
//

import Foundation

// MARK: - EventHandler

/// 事件处理器，管理事件的注册、分发和移除
final class EventHandler: EventHandlerProtocol {

    // MARK: - HandlerInfo

    private struct HandlerInfo {
        weak var observer: AnyObject?
        let handler: EventHandlerBlock
        var options: EventOption
        let identifier: String
    }

    // MARK: - HandlerType

    /// 处理器类型，用于区分普通/before/after
    enum HandlerType {
        case normal
        case before
        case after
    }

    // MARK: - Properties

    private var handlers: [Event: [HandlerInfo]] = [:]
    private var beforeHandlers: [Event: [HandlerInfo]] = [:]
    private var afterHandlers: [Event: [HandlerInfo]] = [:]
    private var handlerIdentifier = 0
    private var lock = os_unfair_lock()

    // MARK: - Add Observer

    /// 添加事件监听（无选项）
    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        add(observer, event: event, option: [], handler: handler)
    }

    /// 添加多个事件的监听
    func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        let tokens = events.compactMap { add(observer, event: $0, handler: handler) }
        return tokens.isEmpty ? nil : MultiHandlerToken(tokens: tokens)
    }

    /// 添加带选项的事件监听
    func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        addHandler(observer, event: event, option: option, handler: handler, type: .normal)
    }

    /// 添加事件发送之前的监听器（AOP）
    func add(_ observer: AnyObject, beforeEvent event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        addHandler(observer, event: event, option: [], handler: handler, type: .before)
    }

    /// 添加事件发送之后的监听器（AOP）
    func add(_ observer: AnyObject, afterEvent event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        addHandler(observer, event: event, option: [], handler: handler, type: .after)
    }

    /// 通用的添加处理器方法
    private func addHandler(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock, type: HandlerType) -> AnyObject? {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        let identifier = generateIdentifier()
        let info = HandlerInfo(
            observer: observer,
            handler: handler,
            options: option,
            identifier: identifier
        )

        switch type {
        case .normal:
            handlers[event, default: []].append(info)
        case .before:
            beforeHandlers[event, default: []].append(info)
        case .after:
            afterHandlers[event, default: []].append(info)
        }

        return AOPHandlerToken(event: event, identifier: identifier, handler: self, type: type)
    }

    // MARK: - Remove Handler

    /// 移除指定的事件处理器
    func removeHandler(_ token: AnyObject) {
        switch token {
        case let t as AOPHandlerToken:
            removeHandler(for: t)
        case let t as MultiHandlerToken:
            t.tokens.forEach { removeHandler($0) }
        default:
            break
        }
    }

    private func removeHandler(for token: AOPHandlerToken) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        let targetHandlers: [Event: [HandlerInfo]]
        switch token.type {
        case .normal:
            targetHandlers = handlers
        case .before:
            targetHandlers = beforeHandlers
        case .after:
            targetHandlers = afterHandlers
        }

        guard var infos = targetHandlers[token.event] else { return }
        infos.removeAll { $0.identifier == token.identifier }

        if infos.isEmpty {
            switch token.type {
            case .normal:
                handlers.removeValue(forKey: token.event)
            case .before:
                beforeHandlers.removeValue(forKey: token.event)
            case .after:
                afterHandlers.removeValue(forKey: token.event)
            }
        } else {
            switch token.type {
            case .normal:
                handlers[token.event] = infos
            case .before:
                beforeHandlers[token.event] = infos
            case .after:
                afterHandlers[token.event] = infos
            }
        }
    }

    /// 移除指定观察者的所有事件处理器
    func removeHandlers(forObserver observer: AnyObject) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        // 移除普通 handlers
        for event in handlers.keys {
            handlers[event]?.removeAll { $0.observer === observer }
        }
        handlers = handlers.filter { !$0.value.isEmpty }

        // 移除 before handlers
        for event in beforeHandlers.keys {
            beforeHandlers[event]?.removeAll { $0.observer === observer }
        }
        beforeHandlers = beforeHandlers.filter { !$0.value.isEmpty }

        // 移除 after handlers
        for event in afterHandlers.keys {
            afterHandlers[event]?.removeAll { $0.observer === observer }
        }
        afterHandlers = afterHandlers.filter { !$0.value.isEmpty }
    }

    /// 移除所有事件处理器
    func removeAllHandler() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        handlers.removeAll()
        beforeHandlers.removeAll()
        afterHandlers.removeAll()
    }

    // MARK: - Post Event

    /// 发送事件（带数据）
    /// 执行顺序: before handlers -> normal handlers -> after handlers
    func post(_ event: Event, object: Any?, sender: AnyObject) {
        // 1. 执行 before handlers
        let beforeSnapshot = handlerSnapshot(for: event, type: .before)
        notifyHandlers(beforeSnapshot, event: event, object: object)

        // 2. 执行 normal handlers
        let snapshot = handlerSnapshot(for: event, type: .normal)
        var identifiersToRemove: [String] = []

        for info in snapshot {
            guard info.observer != nil else {
                identifiersToRemove.append(info.identifier)
                continue
            }

            info.handler(object, event)

            if info.options.contains(.execOnlyOnce) {
                identifiersToRemove.append(info.identifier)
            }
        }

        cleanupHandlers(for: event, identifiersToRemove: identifiersToRemove, type: .normal)

        // 3. 执行 after handlers
        let afterSnapshot = handlerSnapshot(for: event, type: .after)
        notifyHandlers(afterSnapshot, event: event, object: object)
    }

    /// 发送事件（无数据）
    func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    // MARK: - Private

    private func generateIdentifier() -> String {
        handlerIdentifier += 1
        return "handler_\(handlerIdentifier)_\(UUID().uuidString)"
    }

    private func handlerSnapshot(for event: Event, type: HandlerType) -> [HandlerInfo] {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        switch type {
        case .normal:
            return handlers[event] ?? []
        case .before:
            return beforeHandlers[event] ?? []
        case .after:
            return afterHandlers[event] ?? []
        }
    }

    private func notifyHandlers(_ handlers: [HandlerInfo], event: Event, object: Any?) {
        for info in handlers {
            guard info.observer != nil else { continue }
            info.handler(object, event)
        }
    }

    private func cleanupHandlers(for event: Event, identifiersToRemove: [String], type: HandlerType) {
        guard !identifiersToRemove.isEmpty else { return }

        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        switch type {
        case .normal:
            handlers[event]?.removeAll { identifiersToRemove.contains($0.identifier) }
        case .before:
            beforeHandlers[event]?.removeAll { identifiersToRemove.contains($0.identifier) }
        case .after:
            afterHandlers[event]?.removeAll { identifiersToRemove.contains($0.identifier) }
        }
    }
}

// MARK: - AOPHandlerToken

/// 统一的处理器 Token，支持 normal/before/after 类型
private final class AOPHandlerToken: NSObject {
    let event: Event
    let identifier: String
    weak var handler: EventHandler?
    let type: EventHandler.HandlerType

    init(event: Event, identifier: String, handler: EventHandler, type: EventHandler.HandlerType) {
        self.event = event
        self.identifier = identifier
        self.handler = handler
        self.type = type
        super.init()
    }
}

// MARK: - MultiHandlerToken

private final class MultiHandlerToken: NSObject {
    let tokens: [AnyObject]

    init(tokens: [AnyObject]) {
        self.tokens = tokens
        super.init()
    }
}
