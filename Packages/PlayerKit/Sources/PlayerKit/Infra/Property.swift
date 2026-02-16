//
//  Property.swift
//  playerkit
//

import Foundation

/** 插件依赖注入属性包装器，通过 Context 自动解析服务实例 */
@propertyWrapper
public final class PlayerPlugin<Service> {

    /** 所属 Context 的弱引用 */
    private weak var context: ContextProtocol?
    /** 要解析的服务协议类型 */
    private let serviceType: Any.Type

    /** 初始化属性包装器，指定服务协议类型 */
    public init(serviceType: Any.Type) {
        self.serviceType = serviceType
    }

    /** 包装值，通过 Context 动态解析服务实例 */
    @MainActor
    public var wrappedValue: Service? {
        get {
            guard let context = context else {
                return nil
            }
            return context.resolveServiceByType(serviceType) as? Service
        }
        set {
        }
    }

    /** 设置 Context 引用，用于后续的服务解析 */
    internal func setContext(_ context: ContextProtocol?) {
        self.context = context
    }
}

extension BasePlugin {

    /** 遍历属性包装器并注入 Context，实现自动依赖注入 */
    internal func setupPropertyWrappers() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let serviceWrapper = child.value as? any PlayerPluginWrapper {
                serviceWrapper.setContext(context)
            }
        }
    }
}

/** 插件属性包装器内部协议，用于统一设置 Context */
internal protocol PlayerPluginWrapper {
    /** 设置 Context 引用 */
    func setContext(_ context: ContextProtocol?)
}

extension PlayerPlugin: PlayerPluginWrapper {}
