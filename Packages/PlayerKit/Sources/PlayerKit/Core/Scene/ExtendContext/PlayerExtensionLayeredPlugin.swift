import Foundation

@MainActor
public final class PlayerExtensionLayeredPlugin: BasePlugin, PlayerExtensionLayeredService {

    private var _hasExtended: Bool = false
    private var isUnextending: Bool = false
    private weak var _baseContext: PublicContext?

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        (self.context as? Context)?.bindStickyEvent(.extensionDidAddToContextSticky, value: _hasExtended)
    }

    public override func contextDidExtend(on baseContext: PublicContext) {
        super.contextDidExtend(on: baseContext)
        isUnextending = false
        _hasExtended = true
        _baseContext = baseContext
        context?.post(.extensionDidAddToContextSticky, sender: self)
    }

    public override func contextWillUnextend(on baseContext: PublicContext) {
        super.contextWillUnextend(on: baseContext)
        isUnextending = true
        context?.post(.extensionWillRemoveFromContext, sender: self)
        isUnextending = false
        _hasExtended = false
        _baseContext = nil
    }

    // MARK: - PlayerExtensionLayeredService

    public var hasExtended: Bool {
        _hasExtended
    }

    public var baseContext: PublicContext? {
        _baseContext
    }

    public func execExtend(_ extendBlock: (() -> Void)?, execUnExtend unExtendBlock: (() -> Void)?) {
        execLayeredBlock { isExtend in
            if isExtend {
                extendBlock?()
            } else {
                unExtendBlock?()
            }
        }
    }

    public func execLayeredBlock(_ layeredBlock: ((_ isExtend: Bool) -> Void)?) {
        guard _hasExtended, _baseContext != nil else {
            return
        }
        if isUnextending {
            layeredBlock?(false)
        } else {
            layeredBlock?(true)
        }
    }
}
