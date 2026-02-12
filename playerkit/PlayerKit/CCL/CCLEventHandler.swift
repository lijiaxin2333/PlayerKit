//
//  CCLEventHandler.swift
//  playerkit
//
//  CCL 事件处理器实现
//

import Foundation

// MARK: - CCL 事件处理器

final class CCLEventHandler: CCLEventHandlerProtocol {

    // MARK: - Nested Types

    private struct HandlerInfo {
        weak var observer: AnyObject?
        let handler: CCLEventHandlerBlock
        var options: CCLEventOption
        let identifier: String
    }

    // MARK: - Properties

    private var handlers: [CCLEvent: [HandlerInfo]] = [:]
    private let lock = NSLock()
    private var handlerIdentifier = 0

    // MARK: - CCLEventHandlerProtocol

    func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        return add(observer, event: event, option: .none, handler: handler)
    }

    func add(_ observer: AnyObject, events: [CCLEvent], handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        let identifier = generateIdentifier()
        var tokens: [AnyObject] = []

        for event in events {
            if let token = add(observer, event: event, option: .none, handler: handler) {
                tokens.append(token)
            }
        }

        return MultiEventHandlerToken(tokens: tokens, identifier: identifier)
    }

    func add(_ observer: AnyObject, event: CCLEvent, option: CCLEventOption, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
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

        // 如果设置了 execWhenAdd，立即执行一次
        if option.contains(.execWhenAdd) {
            handler(nil, event)
        }

        return HandlerToken(event: event, identifier: info.identifier, handler: self)
    }

    func removeHandler(_ handler: AnyObject) {
        guard let token = handler as? HandlerToken else {
            // 处理 MultiEventHandlerToken
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

    func removeAllHandler() {
        lock.lock()
        defer { lock.unlock() }

        handlers.removeAll()
    }

    func post(_ event: CCLEvent, object: Any?, sender: AnyObject) {
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

        // 清理已经释放的 observer
        lock.lock()
        handlers[event]?.removeAll { $0.observer == nil }
        lock.unlock()
    }

    func post(_ event: CCLEvent, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    // MARK: - Private

    private func generateIdentifier() -> String {
        handlerIdentifier += 1
        return "handler_\(handlerIdentifier)_\(UUID().uuidString)"
    }
}

// MARK: - Handler Token

private final class HandlerToken: NSObject {
    let event: CCLEvent
    let identifier: String
    weak var handler: CCLEventHandler?

    init(event: CCLEvent, identifier: String, handler: CCLEventHandler) {
        self.event = event
        self.identifier = identifier
        self.handler = handler
    }
}

private final class MultiEventHandlerToken: NSObject {
    let tokens: [AnyObject]
    let identifier: String

    init(tokens: [AnyObject], identifier: String) {
        self.tokens = tokens
        self.identifier = identifier
    }
}

// MARK: - Sticky Event 支持

extension CCLEventHandler {

    /// 绑定粘性事件
    func bindStickyEvent(_ event: CCLEvent, value: Any?) {
        // 粘性事件的值存储，后续添加监听时可以立即获取到
    }

    /// 触发绑定的粘性事件
    func triggerBindedStickyEvent(_ event: CCLEvent, to observer: AnyObject, handler: @escaping CCLEventHandlerBlock) -> Bool {
        // 检查是否有绑定的粘性事件
        return false
    }
}
