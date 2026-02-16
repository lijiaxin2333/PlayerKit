//
//  EventHandler.swift
//  playerkit
//

import Foundation

final class EventHandler: EventHandlerProtocol {

    private struct HandlerInfo {
        weak var observer: AnyObject?
        let handler: EventHandlerBlock
        var options: EventOption
        let identifier: String
    }

    private var handlers: [Event: [HandlerInfo]] = [:]
    private let lock = NSLock()
    private var handlerIdentifier = 0

    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        return add(observer, event: event, option: .none, handler: handler)
    }

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

    func post(_ event: Event, sender: AnyObject) {
        post(event, object: nil, sender: sender)
    }

    private func generateIdentifier() -> String {
        handlerIdentifier += 1
        return "handler_\(handlerIdentifier)_\(UUID().uuidString)"
    }
}

private final class HandlerToken: NSObject {
    let event: Event
    let identifier: String
    weak var handler: EventHandler?

    init(event: Event, identifier: String, handler: EventHandler) {
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

extension EventHandler {

    func bindStickyEvent(_ event: Event, value: Any?) {
    }

    func triggerBindedStickyEvent(_ event: Event, to observer: AnyObject, handler: @escaping EventHandlerBlock) -> Bool {
        return false
    }
}
