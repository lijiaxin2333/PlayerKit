import Foundation

@MainActor
public final class PlayerTypedPlayerLayeredComp: CCLBaseComp, PlayerTypedPlayerLayeredService {

    private var _hasPlayer: Bool = false
    private var isRemovingTypedPlayer: Bool = false
    private weak var _typedContext: CCLContextProtocol?

    public required override init() {
        super.init()
    }

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
        (self.context as? CCLContext)?.bindStickyEvent(.typedPlayerDidAddToSceneSticky, value: _hasPlayer)
    }

    public override func contextDidAddSubContext(_ subContext: CCLPublicContext) {
        super.contextDidAddSubContext(subContext)

        if let holder = subContext.holder, holder is any TypedPlayerProtocol {
            _hasPlayer = true
            _typedContext = subContext
            context?.post(.typedPlayerDidAddToSceneSticky, sender: self)
        }
    }

    public override func contextWillRemoveSubContext(_ subContext: CCLPublicContext) {
        super.contextWillRemoveSubContext(subContext)

        if let holder = subContext.holder, holder is any TypedPlayerProtocol {
            isRemovingTypedPlayer = true
            context?.post(.typedPlayerWillRemoveFromScene, sender: self)
            _hasPlayer = false
            _typedContext = nil
            isRemovingTypedPlayer = false
        }
    }

    // MARK: - PlayerTypedPlayerLayeredService

    public var hasPlayer: Bool {
        _hasPlayer
    }

    public var typedContext: CCLContextProtocol? {
        _typedContext
    }

    public func execConfigPlayer(_ configBlock: ConfigTypedPlayerBlock?, execResetPlayer resetBlock: ResetTypedPlayerBlock?) {
        execLayeredBlock { isConfig in
            if isConfig {
                configBlock?()
            } else {
                resetBlock?()
            }
        }
    }

    public func execLayeredBlock(_ layeredBlock: TypedPlayerLayeredBlock?) {
        guard _hasPlayer, _typedContext != nil else {
            return
        }

        if isRemovingTypedPlayer {
            layeredBlock?(false)
        } else {
            layeredBlock?(true)
        }
    }
}
