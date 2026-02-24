import UIKit
import PlayerKit

@MainActor
class ShowcaseFeedCellViewConfigModel {
    weak var contentView: UIView?
    weak var playerContainer: UIView?

    init(contentView: UIView, playerContainer: UIView) {
        self.contentView = contentView
        self.playerContainer = playerContainer
    }
}

@MainActor
protocol ShowcaseFeedCellViewService: PluginService {
    var playerContainerView: UIView? { get }
    var contentView: UIView? { get }
}

@MainActor
final class ShowcaseFeedCellViewPlugin: BasePlugin, ShowcaseFeedCellViewService {

    private weak var _contentView: UIView?
    private weak var _playerContainer: UIView?

    var playerContainerView: UIView? { _playerContainer }
    var contentView: UIView? { _contentView }

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    required override init() {
        super.init()
    }

    override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        context.add(self, event: .showcaseFeedCellViewDidSet) { [weak self] object, _ in
            guard let self = self,
                  let model = object as? ShowcaseFeedCellViewConfigModel else { return }
            self._contentView = model.contentView
            self._playerContainer = model.playerContainer
            self.context?.post(.showcaseFeedCellViewDidSetSticky, object: model, sender: self)
        }
        context.add(self, event: .playerEngineDidCreateSticky, option: .none) { [weak self] _, _ in
            self?.attachPlayerViewIfNeeded()
        }
    }

    override func contextDidAddSubContext(_ subContext: PublicContext) {
        attachPlayerViewIfNeeded()
    }

    override func contextWillRemoveSubContext(_ subContext: PublicContext) {
        detachPlayerView()
    }

    private func attachPlayerViewIfNeeded() {
        guard let container = _playerContainer else { return }
        guard let pv = engineService?.playerView else { return }
        if pv.superview === container {
            if let rv = pv as? PlayerEngineRenderView {
                rv.isHidden = false
                rv.ensurePlayerBound()
            }
            return
        }
        detachPlayerView()
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        container.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: container.topAnchor),
            pv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        container.layoutIfNeeded()
        if let renderView = pv as? PlayerEngineRenderView {
            renderView.ensurePlayerBound()
        }
    }

    private func detachPlayerView() {
        guard let container = _playerContainer else { return }
        container.subviews.forEach { $0.removeFromSuperview() }
    }
}
