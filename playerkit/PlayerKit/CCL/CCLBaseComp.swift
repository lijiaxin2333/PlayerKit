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

    public func config(_ configModel: Any?) {
        self._configModel = configModel
    }

    // MARK: - CCLCompProtocol - 生命周期回调（直接在基类中实现以支持多态）

    public func componentDidLoad(_ context: CCLContextProtocol) {
        setupPropertyWrappers()
    }

    public func componentWillUnload(_ context: CCLContextProtocol) {
        // 子类重写此方法
    }

    // MARK: - 上下文变化回调

    public func contextDidAddToSuperContext(_ superContext: CCLPublicContext) {
        // 子类重写
    }

    public func contextWillRemoveFromSuperContext(_ superContext: CCLPublicContext) {
        // 子类重写
    }

    public func contextDidAddSubContext(_ subContext: CCLPublicContext) {
        // 子类重写
    }

    public func contextWillRemoveSubContext(_ subContext: CCLPublicContext) {
        // 子类重写
    }

    public func contextDidExtend(on baseContext: CCLPublicContext) {
        // 子类重写
    }

    public func contextWillUnextend(on baseContext: CCLPublicContext) {
        // 子类重写
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
