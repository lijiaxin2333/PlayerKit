import Foundation

public extension CCLEvent {
    static let typedPlayerDidAddToSceneSticky: CCLEvent = "TypedPlayerDidAddToSceneSticky"
    static let typedPlayerWillRemoveFromScene: CCLEvent = "TypedPlayerWillRemoveFromScene"
}

@MainActor
public protocol PlayerTypedPlayerLayeredService: CCLCompService {

    var hasPlayer: Bool { get }

    var typedContext: CCLContextProtocol? { get }

    typealias ConfigTypedPlayerBlock = () -> Void
    typealias ResetTypedPlayerBlock = () -> Void

    func execConfigPlayer(_ configBlock: ConfigTypedPlayerBlock?, execResetPlayer resetBlock: ResetTypedPlayerBlock?)

    typealias TypedPlayerLayeredBlock = (_ isConfig: Bool) -> Void

    func execLayeredBlock(_ layeredBlock: TypedPlayerLayeredBlock?)
}
