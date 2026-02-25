import UIKit
import PlayerKit

/// Feed Cell 视图服务插件
/// 职责：仅存储 Cell 视图容器的引用，供其他插件访问
/// 注意：不负责贴播放器视图，贴视图由 Cell 层统一处理
@MainActor
public final class ShowcaseFeedCellViewPlugin: BasePlugin, ShowcaseFeedCellViewService {

    private weak var _contentView: UIView?
    private weak var _playerContainer: UIView?

    public var playerContainerView: UIView? { _playerContainer }
    public var contentView: UIView? { _contentView }

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        context.add(self, event: .showcaseFeedCellViewDidSet) { [weak self] object, _ in
            guard let self = self,
                  let model = object as? ShowcaseFeedCellViewConfigModel else { return }
            self._contentView = model.contentView
            self._playerContainer = model.playerContainer
            self.context?.post(.showcaseFeedCellViewDidSetSticky, object: model, sender: self)
        }
    }
}
