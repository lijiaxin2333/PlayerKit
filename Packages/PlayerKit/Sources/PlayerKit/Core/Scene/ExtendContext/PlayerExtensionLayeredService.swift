import Foundation

public extension CCLEvent {
    static let extensionDidAddToContextSticky: CCLEvent = "ExtensionDidAddToContextSticky"
    static let extensionWillRemoveFromContext: CCLEvent = "ExtensionWillRemoveFromContext"
}

@MainActor
public protocol PlayerExtensionLayeredService: CCLCompService {

    var hasExtended: Bool { get }

    var baseContext: CCLPublicContext? { get }

    func execExtend(_ extendBlock: (() -> Void)?, execUnExtend unExtendBlock: (() -> Void)?)

    func execLayeredBlock(_ layeredBlock: ((_ isExtend: Bool) -> Void)?)
}
