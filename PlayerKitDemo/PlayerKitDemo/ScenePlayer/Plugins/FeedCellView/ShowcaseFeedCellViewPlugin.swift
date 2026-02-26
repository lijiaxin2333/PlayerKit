import UIKit
import PlayerKit

/// Feed Cell 视图服务插件
/// 职责：仅存储 Cell 视图容器的引用，供其他插件访问
/// 注意：不负责贴播放器视图，贴视图由 Cell 层统一处理
@MainActor
public final class ShowcaseFeedCellViewPlugin: BasePlugin, ShowcaseFeedCellViewService {

    public typealias ConfigModelType = ShowcaseFeedCellViewPluginConfigModel
    
    private weak var _contentView: UIView?
    private weak var _playerContainer: UIView?

    public var playerContainerView: UIView? { _playerContainer }
    public var contentView: UIView? { _contentView }

    public required init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }
    
    public override func config(_ configModel: Any?) {
        guard let configModel = configModel as? ConfigModelType else {
            return
        }
        self._playerContainer = configModel.playerContainer
        self._contentView = configModel.contentView
    }
}
