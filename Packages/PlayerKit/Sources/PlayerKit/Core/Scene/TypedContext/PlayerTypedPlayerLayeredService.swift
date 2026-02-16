import Foundation

public extension Event {
    static let typedPlayerDidAddToSceneSticky: Event = "TypedPlayerDidAddToSceneSticky"
    static let typedPlayerWillRemoveFromScene: Event = "TypedPlayerWillRemoveFromScene"
}

@MainActor
public protocol PlayerTypedPlayerLayeredService: PluginService {

    var hasPlayer: Bool { get }

    var typedContext: ContextProtocol? { get }

    typealias ConfigTypedPlayerBlock = () -> Void
    typealias ResetTypedPlayerBlock = () -> Void

    func execConfigPlayer(_ configBlock: ConfigTypedPlayerBlock?, execResetPlayer resetBlock: ResetTypedPlayerBlock?)

    typealias TypedPlayerLayeredBlock = (_ isConfig: Bool) -> Void

    func execLayeredBlock(_ layeredBlock: TypedPlayerLayeredBlock?)
}
