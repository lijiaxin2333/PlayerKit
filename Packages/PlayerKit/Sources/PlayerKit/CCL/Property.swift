//
//  Property.swift
//  playerkit
//

import Foundation

@propertyWrapper
public final class PlayerPlugin<Service> {

    private weak var context: ContextProtocol?
    private let serviceType: Any.Type

    public init(serviceType: Any.Type) {
        self.serviceType = serviceType
    }

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

    internal func setContext(_ context: ContextProtocol?) {
        self.context = context
    }
}

extension BasePlugin {

    internal func setupPropertyWrappers() {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let serviceWrapper = child.value as? any PlayerPluginWrapper {
                serviceWrapper.setContext(context)
            }
        }
    }
}

internal protocol PlayerPluginWrapper {
    func setContext(_ context: ContextProtocol?)
}

extension PlayerPlugin: PlayerPluginWrapper {}
