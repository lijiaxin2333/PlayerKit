//
//  ContextTests.swift
//  PlayerKitTests
//
//  测试 Context 的事件通知系统
//

import XCTest
@testable import BizPlayerKit

@MainActor
final class ContextTests: XCTestCase {

    // MARK: - Helper Types

    /// 测试用观察者
    final class TestObserver: NSObject {
        var eventCount = 0
        var lastEvent: Event?
        var lastObject: Any?

        func reset() {
            eventCount = 0
            lastEvent = nil
            lastObject = nil
        }
    }

    // MARK: - Basic Event Tests

    /// 测试基本事件添加和发送
    func testAddAndPostEvent() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 添加事件监听
        context.add(observer, event: "testEvent") { object, event in
            observer.eventCount += 1
            observer.lastEvent = event
            observer.lastObject = object
        }

        // 发送事件
        context.post("testEvent", object: "testData", sender: self)

        // 验证
        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastEvent, "testEvent")
        XCTAssertEqual(observer.lastObject as? String, "testData")
    }

    /// 测试发送无数据事件
    func testPostEventWithoutObject() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        context.add(observer, event: "simpleEvent") { _, event in
            observer.eventCount += 1
            observer.lastEvent = event
        }

        context.post("simpleEvent", sender: self)

        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastEvent, "simpleEvent")
        XCTAssertNil(observer.lastObject)
    }

    /// 测试多事件监听
    func testAddMultipleEvents() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 监听多个事件
        context.add(observer, events: ["event1", "event2", "event3"]) { object, event in
            observer.eventCount += 1
            observer.lastEvent = event
        }

        // 发送不同事件
        context.post("event1", sender: self)
        context.post("event2", sender: self)
        context.post("event3", sender: self)

        // 应该收到 3 次事件
        XCTAssertEqual(observer.eventCount, 3)
    }

    // MARK: - Event Option Tests

    /// 测试 EventOption.none 选项
    func testEventOptionNone() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 使用默认选项（none）
        context.add(observer, event: "normalEvent", option: .none) { _, _ in
            observer.eventCount += 1
        }

        // 添加时不应该执行
        XCTAssertEqual(observer.eventCount, 0)

        // 发送时才执行
        context.post("normalEvent", sender: self)
        XCTAssertEqual(observer.eventCount, 1)
    }

    /// 测试 execOnlyOnce 选项
    func testExecOnlyOnceOption() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 使用 execOnlyOnce 选项，只执行一次后自动移除
        context.add(observer, event: "onceEvent", option: .execOnlyOnce) { _, _ in
            observer.eventCount += 1
        }

        // 发送多次
        context.post("onceEvent", sender: self)
        context.post("onceEvent", sender: self)
        context.post("onceEvent", sender: self)

        // 应该只执行一次
        XCTAssertEqual(observer.eventCount, 1)
    }

    /// 测试选项的行为
    func testEventOptions() async {
        let context = Context(name: "TestContext")

        // 测试 none 选项
        XCTAssertFalse(EventOption.none.contains(.execWhenAdd))
        XCTAssertFalse(EventOption.none.contains(.execOnlyOnce))

        // 测试单独选项
        XCTAssertTrue(EventOption.execWhenAdd.contains(.execWhenAdd))
        XCTAssertFalse(EventOption.execWhenAdd.contains(.execOnlyOnce))

        XCTAssertTrue(EventOption.execOnlyOnce.contains(.execOnlyOnce))
        XCTAssertFalse(EventOption.execOnlyOnce.contains(.execWhenAdd))

        // 测试组合选项
        let combined: EventOption = [.execWhenAdd, .execOnlyOnce]
        XCTAssertTrue(combined.contains(.execWhenAdd))
        XCTAssertTrue(combined.contains(.execOnlyOnce))
    }

    // MARK: - AOP Tests (Before/After)

    /// 测试 beforeEvent AOP
    func testBeforeEvent() async {
        let context = Context(name: "TestContext")
        var executionOrder: [String] = []

        context.add(self, event: "aopEvent") { _, _ in
            executionOrder.append("normal")
        }

        context.add(self, beforeEvent: "aopEvent") { _, _ in
            executionOrder.append("before")
        }

        context.post("aopEvent", sender: self)

        // before 应该先执行
        XCTAssertEqual(executionOrder, ["before", "normal"])
    }

    /// 测试 afterEvent AOP
    func testAfterEvent() async {
        let context = Context(name: "TestContext")
        var executionOrder: [String] = []

        context.add(self, event: "aopEvent") { _, _ in
            executionOrder.append("normal")
        }

        context.add(self, afterEvent: "aopEvent") { _, _ in
            executionOrder.append("after")
        }

        context.post("aopEvent", sender: self)

        // after 应该最后执行
        XCTAssertEqual(executionOrder, ["normal", "after"])
    }

    /// 测试完整的 AOP 执行顺序: before -> normal -> after
    func testFullAOPOrder() async {
        let context = Context(name: "TestContext")
        var executionOrder: [String] = []

        context.add(self, event: "fullAopEvent") { _, _ in
            executionOrder.append("normal")
        }

        context.add(self, beforeEvent: "fullAopEvent") { _, _ in
            executionOrder.append("before")
        }

        context.add(self, afterEvent: "fullAopEvent") { _, _ in
            executionOrder.append("after")
        }

        context.post("fullAopEvent", sender: self)

        XCTAssertEqual(executionOrder, ["before", "normal", "after"])
    }

    // MARK: - Remove Handler Tests

    /// 测试通过 token 移除处理器
    func testRemoveHandlerByToken() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        let token = context.add(observer, event: "removableEvent") { _, _ in
            observer.eventCount += 1
        }

        // 发送一次，应该收到
        context.post("removableEvent", sender: self)
        XCTAssertEqual(observer.eventCount, 1)

        // 移除处理器
        if let token = token {
            context.removeHandler(token)
        }

        // 再发送，不应该收到
        context.post("removableEvent", sender: self)
        XCTAssertEqual(observer.eventCount, 1)
    }

    /// 测试移除指定观察者的所有处理器
    func testRemoveHandlersForObserver() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        context.add(observer, event: "event1") { _, _ in
            observer.eventCount += 1
        }
        context.add(observer, event: "event2") { _, _ in
            observer.eventCount += 1
        }

        // 发送两个事件
        context.post("event1", sender: self)
        context.post("event2", sender: self)
        XCTAssertEqual(observer.eventCount, 2)

        // 移除该观察者的所有处理器
        context.removeHandlers(forObserver: observer)

        // 再发送，不应该收到
        context.post("event1", sender: self)
        context.post("event2", sender: self)
        XCTAssertEqual(observer.eventCount, 2)
    }

    /// 测试移除所有处理器
    func testRemoveAllHandlers() async {
        let context = Context(name: "TestContext")
        let observer1 = TestObserver()
        let observer2 = TestObserver()

        context.add(observer1, event: "event1") { _, _ in
            observer1.eventCount += 1
        }
        context.add(observer2, event: "event2") { _, _ in
            observer2.eventCount += 1
        }

        // 发送事件
        context.post("event1", sender: self)
        context.post("event2", sender: self)
        XCTAssertEqual(observer1.eventCount, 1)
        XCTAssertEqual(observer2.eventCount, 1)

        // 移除所有处理器
        context.removeAllHandler()

        // 再发送，都不应该收到
        context.post("event1", sender: self)
        context.post("event2", sender: self)
        XCTAssertEqual(observer1.eventCount, 1)
        XCTAssertEqual(observer2.eventCount, 1)
    }

    // MARK: - Event Propagation Tests

    /// 测试事件向上传播到父 Context
    /// 事件传播方向: 子 Context -> 父 Context
    func testEventPropagationToSuperContext() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        parentContext.addSubContext(childContext)

        let parentObserver = TestObserver()
        parentContext.add(parentObserver, event: "propagatedEvent") { _, _ in
            parentObserver.eventCount += 1
        }

        // 从子 Context 发送事件
        childContext.post("propagatedEvent", sender: self)

        // 父 Context 应该收到
        XCTAssertEqual(parentObserver.eventCount, 1)
    }

    /// 测试事件从父 Context 传播到子 Context
    /// 注意: 根据实现，事件会传播到 superContext (向上) 和 extensionContexts
    /// 从父发送事件时，父自己会收到，然后向上传播到它的父（如果有），同时传播到它的扩展 Context
    /// 但不会向下传播到子 Context（除非子 Context 是扩展 Context）
    func testEventDoesNotPropagateDownToSubContext() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        parentContext.addSubContext(childContext)

        let childObserver = TestObserver()
        childContext.add(childObserver, event: "downwardEvent") { _, _ in
            childObserver.eventCount += 1
        }

        // 从父 Context 发送事件
        parentContext.post("downwardEvent", sender: self)

        // 子 Context 不会收到（因为事件不向下传播到 subContexts）
        XCTAssertEqual(childObserver.eventCount, 0)
    }

    /// 测试事件传播到扩展 Context
    /// 事件会传播到 extensionContexts
    func testEventPropagationToExtendContext() async {
        let baseContext = Context(name: "BaseContext")
        let extContext = Context(name: "ExtensionContext")

        baseContext.addExtendContext(extContext)

        let extObserver = TestObserver()
        extContext.add(extObserver, event: "extendEvent") { _, _ in
            extObserver.eventCount += 1
        }

        // 从基础 Context 发送事件
        baseContext.post("extendEvent", sender: self)

        // 扩展 Context 应该收到
        XCTAssertEqual(extObserver.eventCount, 1)
    }

    // MARK: - Multiple Handlers Tests

    /// 测试同一事件有多个处理器
    func testMultipleHandlersForSameEvent() async {
        let context = Context(name: "TestContext")
        var callCount = 0

        context.add(self, event: "multiHandlerEvent") { _, _ in
            callCount += 1
        }
        context.add(self, event: "multiHandlerEvent") { _, _ in
            callCount += 10
        }
        context.add(self, event: "multiHandlerEvent") { _, _ in
            callCount += 100
        }

        context.post("multiHandlerEvent", sender: self)

        // 所有处理器都应该被调用
        XCTAssertEqual(callCount, 111)
    }
}
