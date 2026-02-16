//
//  BasePlugin.swift
//  playerkit
//

import Foundation

open class BasePlugin: NSObject, PluginProtocol {

    public weak var context: ContextProtocol?

    private var _configModel: Any?
    public var configModel: Any? {
        get { _configModel }
        set {
            _configModel = newValue
            if let model = newValue {
                config(model)
            }
        }
    }

    public var staticModel: Any?

    public required override init() {
        super.init()
    }

    deinit {
    }

    open func config(_ configModel: Any?) {
        self._configModel = configModel
    }

    open func pluginDidLoad(_ context: ContextProtocol) {
        setupPropertyWrappers()
    }

    open func pluginWillUnload(_ context: ContextProtocol) {
    }

    open func contextDidAddToSuperContext(_ superContext: PublicContext) {
    }

    open func contextWillRemoveFromSuperContext(_ superContext: PublicContext) {
    }

    open func contextDidAddSubContext(_ subContext: PublicContext) {
    }

    open func contextWillRemoveSubContext(_ subContext: PublicContext) {
    }

    open func contextDidExtend(on baseContext: PublicContext) {
    }

    open func contextWillUnextend(on baseContext: PublicContext) {
    }
}

open class SharedBasePlugin: BasePlugin {

    public weak var sharedContext: SharedContextProtocol? {
        return context as? SharedContextProtocol
    }
}

extension PluginProtocol {

    public func pluginDidLoad(_ context: ContextProtocol) {
    }

    public func pluginWillUnload(_ context: ContextProtocol) {
    }

    public func config(_ configModel: Any?) {
    }
}
