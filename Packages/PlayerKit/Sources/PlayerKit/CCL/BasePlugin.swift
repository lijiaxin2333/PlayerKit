//
//  BasePlugin.swift
//  playerkit
//

import Foundation

/** 插件基类，所有插件的父类，提供生命周期管理和配置能力 */
open class BasePlugin: NSObject, PluginProtocol {

    /** 插件所属的 Context，弱引用避免循环引用 */
    public weak var context: ContextProtocol?

    /** 配置模型内部存储 */
    private var _configModel: Any?
    /** 配置模型，设置时自动调用 config 方法 */
    public var configModel: Any? {
        get { _configModel }
        set {
            _configModel = newValue
            if let model = newValue {
                config(model)
            }
        }
    }

    /** 静态模型，用于存储不会变更的数据 */
    public var staticModel: Any?

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
    }

    deinit {
    }

    /** 配置插件参数，子类可重写以处理具体配置 */
    open func config(_ configModel: Any?) {
        self._configModel = configModel
    }

    /** 插件加载完成回调，初始化属性包装器的依赖注入 */
    open func pluginDidLoad(_ context: ContextProtocol) {
        setupPropertyWrappers()
    }

    /** 插件即将卸载回调，子类可重写以执行清理操作 */
    open func pluginWillUnload(_ context: ContextProtocol) {
    }

    /** 当前 Context 被添加到父 Context 时调用 */
    open func contextDidAddToSuperContext(_ superContext: PublicContext) {
    }

    /** 当前 Context 即将从父 Context 移除时调用 */
    open func contextWillRemoveFromSuperContext(_ superContext: PublicContext) {
    }

    /** 当前 Context 添加了子 Context 时调用 */
    open func contextDidAddSubContext(_ subContext: PublicContext) {
    }

    /** 当前 Context 即将移除子 Context 时调用 */
    open func contextWillRemoveSubContext(_ subContext: PublicContext) {
    }

    /** 当前 Context 作为扩展被添加到基础 Context 时调用 */
    open func contextDidExtend(on baseContext: PublicContext) {
    }

    /** 当前 Context 即将从基础 Context 解除扩展时调用 */
    open func contextWillUnextend(on baseContext: PublicContext) {
    }
}

/** 共享插件基类，适用于注册到 SharedContext 的插件 */
open class SharedBasePlugin: BasePlugin {

    /** 获取所属的共享 Context */
    public weak var sharedContext: SharedContextProtocol? {
        return context as? SharedContextProtocol
    }
}

extension PluginProtocol {

    /** 默认空实现：插件加载完成 */
    public func pluginDidLoad(_ context: ContextProtocol) {
    }

    /** 默认空实现：插件即将卸载 */
    public func pluginWillUnload(_ context: ContextProtocol) {
    }

    /** 默认空实现：配置插件 */
    public func config(_ configModel: Any?) {
    }
}
