import Foundation

@MainActor
public protocol TypedPlayerProtocol: CCLContextHolder {
}

@MainActor
public protocol ScenePlayerProtocol: CCLContextHolder {

    var context: CCLPublicContext { get }

    var typedPlayer: (any TypedPlayerProtocol)? { get }

    func createTypedPlayer(prerenderKey: String?) -> any TypedPlayerProtocol

    func addTypedPlayer(_ typedPlayer: any TypedPlayerProtocol)

    func removeTypedPlayer()

    func hasTypedPlayer() -> Bool
}

// MARK: - Convenience Extensions

@MainActor
public extension ScenePlayerProtocol {

    /// Post 事件到 context
    func post(_ event: CCLEvent, object: Any? = nil, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    /// 添加事件监听
    func add(_ observer: AnyObject, event: CCLEvent, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        context.add(observer, event: event, handler: handler)
    }

    /// 添加事件监听（带选项）
    func add(_ observer: AnyObject, event: CCLEvent, option: CCLEventOption, handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        context.add(observer, event: event, option: option, handler: handler)
    }

    /// 添加多个事件监听
    func add(_ observer: AnyObject, events: [CCLEvent], handler: @escaping CCLEventHandlerBlock) -> AnyObject? {
        context.add(observer, events: events, handler: handler)
    }

    /// 移除事件监听
    func removeHandlers(forObserver observer: AnyObject) {
        context.removeHandlers(forObserver: observer)
    }

    /// 移除所有监听
    func removeAllHandlers() {
        context.removeAllHandler()
    }

    /// 解析服务
    func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        context.resolveService(serviceProtocol)
    }

    /// 配置组件
    func configComp<Service: CCLCompService>(serviceProtocol: Service.Type, withModel configModel: Any?) {
        context.configComp(serviceProtocol: serviceProtocol, withModel: configModel)
    }
}
