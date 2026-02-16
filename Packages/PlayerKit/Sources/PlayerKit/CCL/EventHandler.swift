//
//  EventHandler.swift
//  playerkit
//

import Foundation

/** 事件处理器，管理事件的注册、分发和移除 */
final class EventHandler: EventHandlerProtocol {

    /** 事件处理信息，记录观察者、回调闭包、选项和唯一标识 */
    private struct HandlerInfo {
        /** 观察者弱引用 */
        weak var observer: AnyObject?
        /** 事件回调闭包 */
        let handler: EventHandlerBlock
        /** 事件处理选项 */
        var options: EventOption
        /** 唯一标识符 */
        let identifier: String
    }

    /** 事件名称到处理信息列表的映射 */
    private var handlers: [Event: [HandlerInfo]] = [:]
    /** 线程安全锁 */
    private let lock = NSLock()
    /** 处理器标识计数器 */
    private var handlerIdentifier = 0

    /** 添加单个事件的监听器，使用默认选项 */
    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return add(observer, event: event, option: .none, handler: handler)
    }

    /** 添加多个事件的监听器，返回多事件 token */
    func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        let identifier = generateIdentifier()
        var tokens: [AnyObject] = []

        for event in events {
            if let token = add(observer, event: event, option: .none, handler: handler) {
                tokens.append(token)
            }
        }

        return MultiEventHandlerToken(tokens: tokens, identifier: identifier)
    }

    /** 添加带选项的事件监听器，支持注册时立即执行 */
    func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        lock.lock()
        defer { lock.unlock() }

        if handlers[event] == nil {
            handlers[event] = []
        }

        let info = HandlerInfo(
            observer: observer,
            handler: handler,
            options: option,
            identifier: generateIdentifier()
        )
        handlers[event]?.append(info)

        if option.contains(.execWhenAdd) {
            handler(nil, event)
        }

        return HandlerToken(event: event, identifier: info.identifier, handler: self)
    }

    /** 通过 token 移除指定的事件处理器 */
    func removeHandler(_ handler: AnyObject) {
        guard let token = handler as? HandlerToken else {
            if let multiToken = handler as? MultiEventHandlerToken {
                for token in multiToken.tokens {
                    removeHandler(token)
                }
            }
            return
        }

        lock.lock()
        defer { lock.unlock() }

        if var array = handlers[token.event] {
            array.removeAll { $0.identifier == token.identifier }
            handlers[token.event] = array.isEmpty ? nil : array
        }
    }

    /** 移除指定观察者的所有事件处理器 */
    func removeHandlers(forObserver observer: AnyObject) {
        lock.lock()
        defer { lock.unlock() }

        for event in handlers.keys {
            if var array = handlers[event] {
                array.removeAll { $0.observer === observer }
                handlers[event] = array.isEmpty ? nil : array
            }
        }
    }

    /** 移除所有事件处理器 */
    func removeAllHandler() {
        lock.lock()
        defer { lock.unlock() }

        handlers.removeAll()
    }

    /** 发送事件，通知所有监听该事件的处理器 */
    func post(_ event: Event, object: Any?, sender: AnyObject) {
        lock.lock()
        let currentHandlers = handlers[event]?.filter { $0.observer != nil } ?? []
        lock.unlock()

        for info in currentHandlers {
            if let observer = info.observer {
                info.handler(object, event)

                if info.options.contains(.execOnlyOnce) {
                    let token = HandlerToken(event: event, identifier: info.identifier, handler: self)
                    removeHandler(token)
                }
            }
        }

        lock.lock()
        handlers[event]?.removeAll { $0.observer == nil }
        lock.unlock()
    }

    /** 发送事件，不携带附加数据 */
    func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    /** 生成唯一的处理器标识符 */
    private func generateIdentifier() -> String {
        handlerIdentifier += 1
        return "handler_\(handlerIdentifier)_\(UUID().uuidString)"
    }
}

/** 单事件处理器 token，用于标识和移除特定的事件处理器 */
private final class HandlerToken: NSObject {
    /** 关联的事件名称 */
    let event: Event
    /** 唯一标识符 */
    let identifier: String
    /** 所属的事件处理器弱引用 */
    weak var handler: EventHandler?

    /** 初始化单事件 token */
    init(event: Event, identifier: String, handler: EventHandler) {
        self.event = event
        self.identifier = identifier
        self.handler = handler
    }
}

/** 多事件处理器 token，封装多个单事件 token */
private final class MultiEventHandlerToken: NSObject {
    /** 内部持有的所有单事件 token */
    let tokens: [AnyObject]
    /** 唯一标识符 */
    let identifier: String

    /** 初始化多事件 token */
    init(tokens: [AnyObject], identifier: String) {
        self.tokens = tokens
        self.identifier = identifier
    }
}

extension EventHandler {

    /** 绑定粘性事件值（预留接口） */
    func bindStickyEvent(_ event: Event, value: Any?) {
    }

    /** 触发已绑定的粘性事件（预留接口） */
    func triggerBindedStickyEvent(_ event: Event, to observer: AnyObject, handler: @escaping EventHandlerBlock) -> Bool {
        return false
    }
}
