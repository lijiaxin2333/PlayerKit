//
//  CCLProperty.swift
//  playerkit
//
//  CCL 依赖注入属性包装器
//

import Foundation

// MARK: - CCL 依赖注入属性包装器

/// CCL 服务依赖注入属性包装器
///
/// 使用方式：
/// ```swift
/// @CCLService var engineService: PlayerEngineService?
/// @CCLService var dataService: PlayerDataService?
/// ```
///
/// 该属性包装器会自动从 context 中解析对应的服务，实现依赖注入
@propertyWrapper
public final class CCLService<Service> {

    // MARK: - Properties

    private weak var context: CCLContextProtocol?
    private let serviceType: Any.Type

    // MARK: - Initialization

    public init(serviceType: Any.Type) {
        self.serviceType = serviceType
    }

    // MARK: - Wrapped Value

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

    internal func setContext(_ context: CCLContextProtocol?) {
        self.context = context
    }
}

// MARK: - CCLBaseComp 扩展 - 属性包装器支持

extension CCLBaseComp {

    /// 设置属性包装器的上下文
    /// 在 componentDidLoad 时调用，让所有 @CCLService 属性可以访问 context
    internal func setupPropertyWrappers() {
        // 使用 Mirror 遍历所有子属性，找到 CCLService 类型的属性并设置其 context
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let serviceWrapper = child.value as? any CCLServiceWrapper {
                serviceWrapper.setContext(context)
            }
        }
    }
}

// MARK: - 服务包装器协议

/// 用于识别 CCLService 属性包装器的协议
internal protocol CCLServiceWrapper {
    func setContext(_ context: CCLContextProtocol?)
}

extension CCLService: CCLServiceWrapper {}
