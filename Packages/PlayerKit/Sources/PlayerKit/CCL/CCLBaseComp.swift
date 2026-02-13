//
//  CCLBaseComp.swift
//  playerkit
//
//  CCL 组件基类
//

import Foundation

// MARK: - CCL 基础组件

open class CCLBaseComp: NSObject, CCLCompProtocol {

    // MARK: - Properties

    public weak var context: CCLContextProtocol?

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

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    deinit {
        // 空实现，允许子类重写
    }

    // MARK: - CCLCompService

    open func config(_ configModel: Any?) {
        self._configModel = configModel
    }

    open func componentDidLoad(_ context: CCLContextProtocol) {
        setupPropertyWrappers()
    }

    open func componentWillUnload(_ context: CCLContextProtocol) {
    }

    open func contextDidAddToSuperContext(_ superContext: CCLPublicContext) {
    }

    open func contextWillRemoveFromSuperContext(_ superContext: CCLPublicContext) {
    }

    open func contextDidAddSubContext(_ subContext: CCLPublicContext) {
    }

    open func contextWillRemoveSubContext(_ subContext: CCLPublicContext) {
    }

    open func contextDidExtend(on baseContext: CCLPublicContext) {
    }

    open func contextWillUnextend(on baseContext: CCLPublicContext) {
    }
}

// MARK: - CCL 共享组件基类

open class CCLSharedBaseComp: CCLBaseComp {

    public weak var sharedContext: CCLSharedContextProtocol? {
        return context as? CCLSharedContextProtocol
    }
}

// MARK: - CCL 默认实现

extension CCLCompProtocol {

    public func componentDidLoad(_ context: CCLContextProtocol) {
        // 默认空实现
    }

    public func componentWillUnload(_ context: CCLContextProtocol) {
        // 默认空实现
    }

    public func config(_ configModel: Any?) {
        // 默认空实现
    }
}
