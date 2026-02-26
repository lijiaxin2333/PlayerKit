//
//  ServiceDiscoveryTests.swift
//  PlayerKitTests
//
//  测试 Context 的服务发现功能
//

import XCTest
@testable import PlayerKit

@MainActor
final class ServiceDiscoveryTests: XCTestCase {

    // MARK: - Test Services and Plugins

    /// 测试服务协议 A
    protocol TestServiceA: PluginService {
        var valueA: String { get }
    }

    /// 测试服务协议 B
    protocol TestServiceB: PluginService {
        var valueB: Int { get }
    }

    /// 测试插件 A
    final class TestPluginA: BasePlugin, TestServiceA {
        var valueA: String = "ServiceA"
    }

    /// 测试插件 B
    final class TestPluginB: BasePlugin, TestServiceB {
        var valueB: Int = 42
    }

    /// 带配置的插件
    final class ConfigurablePlugin: BasePlugin, PluginService {
        var configuredValue: String?

        override func config(_ configModel: Any?) {
            configuredValue = configModel as? String
        }
    }

    /// 测试依赖其他服务的插件
    final class DependentPlugin: BasePlugin, PluginService {
        weak var dependencyA: TestServiceA?

        override func pluginDidLoad(_ context: ContextProtocol) {
            dependencyA = context.service(TestServiceA.self)
        }
    }

    // MARK: - Test RegisterProvider

    class TestRegProvider: RegisterProvider {
        let registerPluginA: Bool
        let registerPluginB: Bool

        init(registerPluginA: Bool = true, registerPluginB: Bool = true) {
            self.registerPluginA = registerPluginA
            self.registerPluginB = registerPluginB
        }

        func registerPlugins(with registerSet: PluginRegisterSet) {
            if registerPluginA {
                registerSet.addEntry(pluginClass: TestPluginA.self, serviceType: TestServiceA.self)
            }
            if registerPluginB {
                registerSet.addEntry(pluginClass: TestPluginB.self, serviceType: TestServiceB.self)
            }
        }
    }

    // MARK: - resolveService Tests

    /// 测试解析已注册的服务
    func testResolveService() async {
        let context = Context(name: "TestContext")
        context.addRegProvider(TestRegProvider())

        let service = context.service(TestServiceA.self)

        XCTAssertNotNil(service)
        XCTAssertEqual(service?.valueA, "ServiceA")
    }

    /// 测试解析未注册的服务（应该打印警告并返回 nil）
    func testResolveUnregisteredService() async {
        let context = Context(name: "TestContext")

        // 未注册的服务应该返回 nil
        let service = context.service(TestServiceA.self)
        XCTAssertNil(service)
    }

    // MARK: - tryResolveService Tests

    /// 测试静默解析服务
    func testTryResolveService() async {
        let context = Context(name: "TestContext")
        context.addRegProvider(TestRegProvider())

        let service = context.tryResolveService(TestServiceA.self)
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.valueA, "ServiceA")
    }

    /// 测试静默解析未注册的服务（不打印警告）
    func testTryResolveUnregisteredService() async {
        let context = Context(name: "TestContext")

        // tryResolveService 不应该打印警告
        let service = context.tryResolveService(TestServiceA.self)
        XCTAssertNil(service)
    }

    // MARK: - checkService Tests

    /// 测试检查服务是否已注册
    func testCheckService() async {
        let context = Context(name: "TestContext")

        // 注册前检查
        XCTAssertFalse(context.checkService(TestServiceA.self))

        // 注册后检查
        context.addRegProvider(TestRegProvider())
        XCTAssertTrue(context.checkService(TestServiceA.self))
    }

    // MARK: - configPlugin Tests

    /// 测试配置插件
    func testConfigPlugin() async {
        let context = Context(name: "TestContext")

        // 创建一个简单的 RegProvider 来注册 ConfigurablePlugin
        class ConfigRegProvider: RegisterProvider {
            func registerPlugins(with registerSet: PluginRegisterSet) {
                registerSet.addEntry(pluginClass: ConfigurablePlugin.self, serviceType: ConfigurablePlugin.self)
            }
        }

        context.addRegProvider(ConfigRegProvider())

        // 配置插件
        context.configPlugin(serviceProtocol: ConfigurablePlugin.self, withModel: "configured")

        let service = context.tryResolveService(ConfigurablePlugin.self) as? ConfigurablePlugin
        XCTAssertEqual(service?.configuredValue, "configured")
    }

    // MARK: - registerInstance Tests

    /// 测试直接注册插件实例
    func testRegisterInstance() async {
        let context = Context(name: "TestContext")

        let plugin = TestPluginA()
        context.registerInstance(plugin, protocol: TestServiceA.self)

        let service = context.service(TestServiceA.self)
        XCTAssertNotNil(service)

        // 应该是同一个实例
        XCTAssertTrue(service === plugin)
    }

    /// 测试分离插件实例
    func testDetachInstance() async {
        let context = Context(name: "TestContext")

        let plugin = TestPluginA()
        context.registerInstance(plugin, protocol: TestServiceA.self)

        // 分离前可以解析
        XCTAssertNotNil(context.tryResolveService(TestServiceA.self))

        // 分离实例
        let detached = context.detachInstance(for: TestServiceA.self)
        XCTAssertNotNil(detached)
        XCTAssertTrue(detached === plugin)

        // 分离后无法解析
        XCTAssertNil(context.tryResolveService(TestServiceA.self))
    }

    // MARK: - unregisterService Tests

    /// 测试注销服务
    func testUnregisterService() async {
        let context = Context(name: "TestContext")
        context.addRegProvider(TestRegProvider())

        // 注销前可以解析
        XCTAssertNotNil(context.tryResolveService(TestServiceA.self))

        // 注销服务
        context.unregisterService(TestServiceA.self)

        // 注销后无法解析
        XCTAssertNil(context.tryResolveService(TestServiceA.self))
    }

    /// 测试通过类注销插件
    func testUnregisterPluginClass() async {
        let context = Context(name: "TestContext")
        context.addRegProvider(TestRegProvider())

        XCTAssertNotNil(context.tryResolveService(TestServiceA.self))

        context.unregisterPluginClass(TestPluginA.self)

        XCTAssertNil(context.tryResolveService(TestServiceA.self))
    }

    // MARK: - Cross Context Service Resolution Tests

    /// 测试从子 Context 解析父 Context 的服务
    /// 注意: 根据实现，resolvePlugin 会先查找当前 context，然后遍历 subContexts，最后查找 baseContext
    /// 但不会向上查找 superContext
    func testChildCannotResolveParentServiceDirectly() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        parentContext.addRegProvider(TestRegProvider())
        parentContext.addSubContext(childContext)

        // 子 Context 无法直接解析父 Context 的服务（除非通过 extendContext）
        // 因为 resolvePlugin 不向上查找 superContext
        let service = childContext.tryResolveService(TestServiceA.self)
        XCTAssertNil(service)
    }

    /// 测试父 Context 可以解析子 Context 的服务
    /// 根据实现，resolvePlugin 会遍历 subContexts 查找服务
    func testParentCanResolveChildService() async {
        let parentContext = Context(name: "ParentContext")
        let childContext = Context(name: "ChildContext")

        parentContext.addSubContext(childContext)
        childContext.addRegProvider(TestRegProvider())

        // 父 Context 可以解析子 Context 的服务
        let service = parentContext.service(TestServiceA.self)
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.valueA, "ServiceA")
    }

    /// 测试扩展 Context 可以解析基础 Context 的服务
    func testExtendContextResolveBaseContextService() async {
        let baseContext = Context(name: "BaseContext")
        let extContext = Context(name: "ExtensionContext")

        baseContext.addRegProvider(TestRegProvider())
        baseContext.addExtendContext(extContext)

        // 扩展 Context 可以解析基础 Context 的服务
        let service = extContext.service(TestServiceA.self)
        XCTAssertNotNil(service)
        XCTAssertEqual(service?.valueA, "ServiceA")
    }
}
