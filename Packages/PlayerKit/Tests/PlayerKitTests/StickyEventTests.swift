//
//  StickyEventTests.swift
//  PlayerKitTests
//
//  测试 Sticky 事件功能
//

import XCTest
@testable import PlayerKit

@MainActor
final class StickyEventTests: XCTestCase {

    // MARK: - Helper Types

    final class TestObserver: NSObject {
        var eventCount = 0
        var lastObject: Any?

        func reset() {
            eventCount = 0
            lastObject = nil
        }
    }

    // MARK: - Test Services

    protocol TestService: PluginService {}

    final class TestPlugin: BasePlugin, TestService {}

    class TestRegProvider: RegisterProvider {
        func registerPlugins(with registerSet: PluginRegisterSet) {
            registerSet.addEntry(pluginClass: TestPlugin.self, serviceType: TestService.self)
        }
    }

    // MARK: - Basic Sticky Event Tests

    /// 测试基本的 sticky 事件绑定和触发
    func testBasicStickyEvent() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 绑定 sticky 事件
        context.bindStickyEvent("stickyEvent") {
            return (true, "stickyData")
        }

        // 添加监听时应该立即触发
        context.add(observer, event: "stickyEvent") { object, _ in
            observer.eventCount += 1
            observer.lastObject = object
        }

        // 应该立即收到一次
        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastObject as? String, "stickyData")
    }

    /// 测试 sticky 事件返回 nil 时不触发
    func testStickyEventNotTriggeredWhenReturnsNil() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 绑定 sticky 事件，但返回 nil
        context.bindStickyEvent("noStickyEvent") {
            return nil
        }

        context.add(observer, event: "noStickyEvent") { _, _ in
            observer.eventCount += 1
        }

        // 不应该触发
        XCTAssertEqual(observer.eventCount, 0)
    }

    /// 测试 sticky 事件使用 .shouldSend 便捷方法
    func testStickyEventWithShouldSend() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        context.bindStickyEvent("convenientStickyEvent") {
            return .shouldSend("convenientData")
        }

        context.add(observer, event: "convenientStickyEvent") { object, _ in
            observer.eventCount += 1
            observer.lastObject = object
        }

        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastObject as? String, "convenientData")
    }

    /// 测试 sticky 事件使用 .notSend() 便捷方法
    func testStickyEventWithNotSend() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        context.bindStickyEvent("notSendEvent") {
            return .notSend()
        }

        context.add(observer, event: "notSendEvent") { _, _ in
            observer.eventCount += 1
        }

        XCTAssertEqual(observer.eventCount, 0)
    }

    // MARK: - Sticky Event with State Tests

    /// 测试 sticky 事件基于状态决定是否触发
    func testStickyEventBasedOnState() async {
        final class StateHolder {
            var hasData: Bool = false
            var data: String?
        }

        let context = Context(name: "TestContext")
        let stateHolder = StateHolder()
        let observer = TestObserver()

        context.bindStickyEvent("stateEvent") {
            guard stateHolder.hasData else { return nil }
            return (true, stateHolder.data)
        }

        // 状态为 false，不触发
        context.add(observer, event: "stateEvent") { _, _ in
            observer.eventCount += 1
        }
        XCTAssertEqual(observer.eventCount, 0)

        // 更新状态
        stateHolder.hasData = true
        stateHolder.data = "nowHaveData"
        observer.reset()

        // 再次添加监听，应该触发
        context.add(observer, event: "stateEvent") { object, _ in
            observer.eventCount += 1
            observer.lastObject = object
        }
        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastObject as? String, "nowHaveData")
    }

    // MARK: - Service Did Load Sticky Event Tests

    /// 测试服务加载后的 sticky 事件
    /// ServiceDidLoadEvent 的格式是 "ServiceDidLoadEvent_{typeKey}"
    /// 当服务加载后，新添加的监听者可以收到该事件
    func testServiceDidLoadStickyEvent() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 先注册服务
        context.addRegProvider(TestRegProvider())

        // 等待插件创建
        _ = context.service(TestService.self)

        // 获取正确的服务 key - 使用 String(reflecting:) 来匹配 Context.typeKey 的实现
        let serviceKey = String(reflecting: TestService.self)
        let eventName = "ServiceDidLoadEvent_\(serviceKey)"

        // 监听 ServiceDidLoadEvent
        context.add(observer, event: eventName) { object, _ in
            observer.eventCount += 1
            observer.lastObject = object
        }

        // 应该立即收到（因为服务已加载）
        XCTAssertEqual(observer.eventCount, 1)
    }

    /// 测试后加载的服务也能触发 sticky 事件给新的监听者
    func testServiceDidLoadForLateListener() async {
        let context = Context(name: "TestContext")

        // 注册并解析服务
        context.addRegProvider(TestRegProvider())
        _ = context.service(TestService.self)

        // 后续添加的监听者应该收到
        let observer2 = TestObserver()
        let serviceKey = String(reflecting: TestService.self)
        let eventName = "ServiceDidLoadEvent_\(serviceKey)"

        context.add(observer2, event: eventName) { _, _ in
            observer2.eventCount += 1
        }

        // observer2 应该立即收到
        XCTAssertEqual(observer2.eventCount, 1)
    }

    // MARK: - Sticky Event Reissue Tests

    /// 测试子 Context 可以触发自己绑定的 sticky 事件
    func testStickyEventInChildContext() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        // 先添加子 Context
        parentContext.addSubContext(childContext)

        // 子 Context 绑定 sticky 事件
        childContext.bindStickyEvent("childStickyEvent") {
            return (true, "childStickyData")
        }

        // 然后在子 Context 添加监听
        let childObserver = TestObserver()
        childContext.add(childObserver, event: "childStickyEvent") { object, _ in
            childObserver.eventCount += 1
            childObserver.lastObject = object
        }

        // 应该收到子 Context 自己的 sticky 事件
        XCTAssertEqual(childObserver.eventCount, 1)
        XCTAssertEqual(childObserver.lastObject as? String, "childStickyData")
    }

    /// 测试添加扩展 Context 时重发 sticky 事件
    func testStickyEventReissueOnAddExtendContext() async {
        let baseContext = Context(name: "BaseContext")
        let extContext = Context(name: "ExtensionContext")

        // 基础 Context 绑定 sticky 事件
        baseContext.bindStickyEvent("baseStickyEvent") {
            return (true, "baseStickyData")
        }

        // 先添加扩展 Context
        baseContext.addExtendContext(extContext)

        // 然后在扩展 Context 添加监听
        let extObserver = TestObserver()
        extContext.add(extObserver, event: "baseStickyEvent") { object, _ in
            extObserver.eventCount += 1
            extObserver.lastObject = object
        }

        // 应该收到基础 Context 的 sticky 事件
        XCTAssertEqual(extObserver.eventCount, 1)
        XCTAssertEqual(extObserver.lastObject as? String, "baseStickyData")
    }

    // MARK: - Sticky Event with Bottom API Tests

    /// 测试底层 API (StickyEventBindBlock)
    func testStickyEventWithBottomAPI() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 使用底层 API
        context.bindStickyEvent("bottomAPIEvent") { shouldSend in
            shouldSend.pointee = true
            return "bottomAPIData"
        }

        context.add(observer, event: "bottomAPIEvent") { object, _ in
            observer.eventCount += 1
            observer.lastObject = object
        }

        XCTAssertEqual(observer.eventCount, 1)
        XCTAssertEqual(observer.lastObject as? String, "bottomAPIData")
    }

    /// 测试底层 API 不触发的情况
    func testStickyEventWithBottomAPINotTriggered() async {
        let context = Context(name: "TestContext")
        let observer = TestObserver()

        // 使用底层 API，不设置 shouldSend
        context.bindStickyEvent("bottomAPINoEvent") { shouldSend in
            shouldSend.pointee = false
            return "ignoredData"
        }

        context.add(observer, event: "bottomAPINoEvent") { _, _ in
            observer.eventCount += 1
        }

        XCTAssertEqual(observer.eventCount, 0)
    }

    // MARK: - Multiple Sticky Events Tests

    /// 测试多个 sticky 事件
    func testMultipleStickyEvents() async {
        let context = Context(name: "TestContext")
        let observer1 = TestObserver()
        let observer2 = TestObserver()

        context.bindStickyEvent("stickyEvent1") {
            return (true, "data1")
        }

        context.bindStickyEvent("stickyEvent2") {
            return (true, "data2")
        }

        context.add(observer1, event: "stickyEvent1") { object, _ in
            observer1.eventCount += 1
            observer1.lastObject = object
        }

        context.add(observer2, event: "stickyEvent2") { object, _ in
            observer2.eventCount += 1
            observer2.lastObject = object
        }

        XCTAssertEqual(observer1.eventCount, 1)
        XCTAssertEqual(observer1.lastObject as? String, "data1")
        XCTAssertEqual(observer2.eventCount, 1)
        XCTAssertEqual(observer2.lastObject as? String, "data2")
    }

    // MARK: - Hierarchical Sticky Event Tests

    /// 测试从子 Context 的 sticky 事件触发父 Context 的监听
    func testChildStickyEventTriggerParentListener() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        parentContext.addSubContext(childContext)

        let parentObserver = TestObserver()

        // 子 Context 绑定 sticky 事件
        childContext.bindStickyEvent("childStickyEvent") {
            return (true, "childStickyData")
        }

        // 父 Context 监听
        parentContext.add(parentObserver, event: "childStickyEvent") { object, _ in
            parentObserver.eventCount += 1
            parentObserver.lastObject = object
        }

        // 应该收到子 Context 的 sticky 事件
        XCTAssertEqual(parentObserver.eventCount, 1)
        XCTAssertEqual(parentObserver.lastObject as? String, "childStickyData")
    }
}
