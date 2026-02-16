import Foundation

public extension Event {
    static let extensionDidAddToContextSticky: Event = "ExtensionDidAddToContextSticky"
    static let extensionWillRemoveFromContext: Event = "ExtensionWillRemoveFromContext"
}

@MainActor
public protocol PlayerExtensionLayeredService: PluginService {

    var hasExtended: Bool { get }

    var baseContext: PublicContext? { get }

    func execExtend(_ extendBlock: (() -> Void)?, execUnExtend unExtendBlock: (() -> Void)?)

    func execLayeredBlock(_ layeredBlock: ((_ isExtend: Bool) -> Void)?)
}
