import Foundation

/**
 * 体裁播放器协议
 * 基于 ContextHolder 的体裁层播放器基协议
 */
@MainActor
public protocol TypedPlayerProtocol: ContextHolder {
}

/**
 * 场景播放器协议
 * 定义场景层的播放器能力，包括创建和管理体裁播放器
 */
@MainActor
public protocol ScenePlayerProtocol: ContextHolder {

    /** 场景的公共 Context */
    var context: PublicContext { get }

    /** 当前关联的体裁播放器 */
    var typedPlayer: (any TypedPlayerProtocol)? { get }

    /**
     * 创建体裁播放器
     * - Parameter prerenderKey: 预渲染 key，可为 nil
     * - Returns: 新创建的体裁播放器实例
     */
    func createTypedPlayer(prerenderKey: String?) -> any TypedPlayerProtocol

    /**
     * 添加体裁播放器到场景
     * - Parameter typedPlayer: 要添加的体裁播放器
     */
    func addTypedPlayer(_ typedPlayer: any TypedPlayerProtocol)

    /** 移除当前体裁播放器 */
    func removeTypedPlayer()

    /**
     * 是否已有体裁播放器
     * - Returns: true 表示已有体裁播放器
     */
    func hasTypedPlayer() -> Bool
}

// MARK: - Convenience Extensions

/**
 * ScenePlayerProtocol 便捷扩展
 * 提供事件发送、监听及服务解析的便捷方法
 */
@MainActor
public extension ScenePlayerProtocol {

    /**
     * 向 context 发送事件
     * - Parameters:
     *   - event: 事件类型
     *   - object: 附加对象，可选
     *   - sender: 发送者
     */
    func post(_ event: Event, object: Any? = nil, sender: AnyObject) {
        context.post(event, object: object, sender: sender)
    }

    /**
     * 添加事件监听
     * - Parameters:
     *   - observer: 观察者
     *   - event: 要监听的事件
     *   - handler: 事件处理回调
     * - Returns: 可用来取消监听的 token
     */
    func add(_ observer: AnyObject, event: Event, handler: @escaping EventHandlerBlock) -> AnyObject? {
        context.add(observer, event: event, handler: handler)
    }

    /**
     * 添加事件监听（带选项）
     * - Parameters:
     *   - observer: 观察者
     *   - event: 要监听的事件
     *   - option: 监听选项
     *   - handler: 事件处理回调
     * - Returns: 可用来取消监听的 token
     */
    func add(_ observer: AnyObject, event: Event, option: EventOption, handler: @escaping EventHandlerBlock) -> AnyObject? {
        context.add(observer, event: event, option: option, handler: handler)
    }

    /**
     * 添加多个事件监听
     * - Parameters:
     *   - observer: 观察者
     *   - events: 要监听的事件列表
     *   - handler: 事件处理回调
     * - Returns: 可用来取消监听的 token
     */
    func add(_ observer: AnyObject, events: [Event], handler: @escaping EventHandlerBlock) -> AnyObject? {
        context.add(observer, events: events, handler: handler)
    }

    /**
     * 移除指定观察者的所有事件监听
     * - Parameter observer: 要移除监听的观察者
     */
    func removeHandlers(forObserver observer: AnyObject) {
        context.removeHandlers(forObserver: observer)
    }

    /** 移除 context 上的所有事件监听 */
    func removeAllHandlers() {
        context.removeAllHandler()
    }

    /**
     * 解析指定协议的服务实例
     * - Parameter serviceProtocol: 服务协议类型
     * - Returns: 解析到的服务实例，若不存在则返回 nil
     */
    func resolveService<T>(_ serviceProtocol: T.Type) -> T? {
        context.resolveService(serviceProtocol)
    }

    /**
     * 配置指定服务的插件
     * - Parameters:
     *   - serviceProtocol: 服务协议类型
     *   - configModel: 配置模型
     */
    func configPlugin<Service: PluginService>(serviceProtocol: Service.Type, withModel configModel: Any?) {
        context.configPlugin(serviceProtocol: serviceProtocol, withModel: configModel)
    }
}
