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

    // MARK: - Properties

    private var handlers: [Event: [HandlerInfo]] = [:]
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
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        let identifier = generateIdentifier()

        handlers[event, default: []].append(HandlerInfo(
            observer: observer,
            handler: handler,
            options: option,
            identifier: identifier
        ))

        if option.contains(.execWhenAdd) {
            handler(nil, event)
        }

        return HandlerToken(event: event, identifier: identifier, handler: self)
    }

    // MARK: - Remove Handler

    /// 移除指定的事件处理器
    func removeHandler(_ token: AnyObject) {
        switch token {
        case let t as HandlerToken:
            removeHandler(for: t)
        case let t as MultiHandlerToken:
            t.tokens.forEach { removeHandler($0) }
        default:
            break
        }
    }

    private func removeHandler(for token: HandlerToken) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        guard var infos = handlers[token.event] else { return }
        infos.removeAll { $0.identifier == token.identifier }

        if infos.isEmpty {
            handlers.removeValue(forKey: token.event)
        } else {
            handlers[token.event] = infos
        }
    }

    /// 移除指定观察者的所有事件处理器
    func removeHandlers(forObserver observer: AnyObject) {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        for event in handlers.keys {
            handlers[event]?.removeAll { $0.observer === observer }
        }
        handlers = handlers.filter { !$0.value.isEmpty }
    }

    /// 移除所有事件处理器
    func removeAllHandler() {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        handlers.removeAll()
    }

    // MARK: - Post Event

    /// 发送事件（带数据）
    func post(_ event: Event, object: Any?, sender: AnyObject) {
        let snapshot = handlerSnapshot(for: event)
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

        cleanupHandlers(for: event, identifiersToRemove: identifiersToRemove)
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

    private func handlerSnapshot(for event: Event) -> [HandlerInfo] {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        return handlers[event] ?? []
    }

    private func cleanupHandlers(for event: Event, identifiersToRemove: [String]) {
        guard !identifiersToRemove.isEmpty else { return }

        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }

        handlers[event]?.removeAll { identifiersToRemove.contains($0.identifier) }
    }
}

// MARK: - HandlerToken

private final class HandlerToken: NSObject {
    let event: Event
    let identifier: String
    weak var handler: EventHandler?

    init(event: Event, identifier: String, handler: EventHandler) {
        self.event = event
        self.identifier = identifier
        self.handler = handler
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
