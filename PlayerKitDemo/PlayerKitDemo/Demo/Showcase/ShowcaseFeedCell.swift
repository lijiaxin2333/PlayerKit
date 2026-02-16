import UIKit
import AVFoundation
import IGListKit
import PlayerKit
import ListKit

/// Showcase Feed Cell
/// 实现 ListCellProtocol，遵循 ListKit 标准模式
/// 播放器相关逻辑通过 sceneContext + Plugin 架构处理
@MainActor
final class ShowcaseFeedCell: UICollectionViewCell, ListCellProtocol {

    static let reuseId = "ShowcaseFeedCell"

    // MARK: - ListCellProtocol

    private var _cellViewModel: ShowcaseFeedCellViewModel?

    /// 绑定 CellViewModel
    func bindCellViewModel(_ cellViewModel: ListCellViewModelProtocol) {
        guard let vm = cellViewModel as? ShowcaseFeedCellViewModel else { return }
        _cellViewModel = vm

        // 通知播放器层更新数据
        let model = ShowcaseFeedDataConfigModel(video: vm.video, index: vm.videoIndex)
        sceneContext.post(.showcaseFeedDataWillUpdate, object: model, sender: self)
    }

    /// 获取当前绑定的 CellViewModel
    func cellViewModel() -> ListCellViewModelProtocol? {
        _cellViewModel
    }

    /// Cell 即将显示
    func cellWillDisplay(duplicateReload: Bool) {
        sceneContext.post(.cellWillDisplay, sender: self)
    }

    /// Cell 已移出屏幕
    func cellDidEndDisplaying(duplicateReload: Bool) {
        sceneContext.post(.cellDidEndDisplaying, sender: self)
    }

    /// VC viewWillAppear
    func cellWillAppearByViewController() {}

    /// VC viewDidAppear
    func cellDidAppearByViewController() {}

    /// VC viewWillDisappear
    func cellWillDisappearByViewController() {}

    /// VC viewDidDisappear
    func cellDidDisappearByViewController() {}

    // MARK: - Properties

    let sceneContext = ShowcaseFeedSceneContext()
    private let _playerContainer = UIView()

    var feedPlayer: FeedPlayer? { sceneContext.feedPlayer }
    var playerContainerView: UIView? { _playerContainer }

    /// 当前视频索引（兼容旧代码）
    var videoIndex: Int {
        _cellViewModel?.videoIndex ?? 0
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        contentView.clipsToBounds = true

        _playerContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_playerContainer)

        NSLayoutConstraint.activate([
            _playerContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            _playerContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            _playerContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            _playerContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        // Post 事件通知 CellView 已就绪
        let cellViewConfig = ShowcaseFeedCellViewConfigModel(contentView: contentView, playerContainer: _playerContainer)
        sceneContext.post(.showcaseFeedCellViewDidSet, object: cellViewConfig, sender: self)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Player Methods

    func addTypedPlayerIfNeeded(_ typedPlayer: FeedPlayer) {
        sceneContext.addTypedPlayer(typedPlayer)
    }

    func attachPlayerView() {
        guard let feedPlayer = sceneContext.feedPlayer else { return }
        guard let pv = feedPlayer.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        _playerContainer.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: _playerContainer.topAnchor),
            pv.leadingAnchor.constraint(equalTo: _playerContainer.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: _playerContainer.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: _playerContainer.bottomAnchor)
        ])
        if let renderView = pv as? PlayerEngineRenderView {
            renderView.ensurePlayerBound()
        }
    }

    func detachPlayer() {
        guard let index = _cellViewModel?.videoIndex else { return }
        PLog.detachPlayerLog(index)
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
        sceneContext.removeTypedPlayer()
    }

    // MARK: - 兼容方法（保持原有调用方式）

    /// 检查数据是否有效
    func checkDataValid(video: ShowcaseVideo) -> Bool {
        guard let currentVideo = sceneContext.dataService?.video else { return false }
        return currentVideo.feedId == video.feedId
    }

    /// 设置数据（如果需要）
    func setDataIfNeeded(video: ShowcaseVideo, index: Int) {
        guard let vm = _cellViewModel else { return }
        // 如果数据相同，不需要更新
        guard vm.video.feedId != video.feedId else { return }
        // 更新 ViewModel
        vm.update(video: video, index: index)
        // 通知播放器层
        let model = ShowcaseFeedDataConfigModel(video: video, index: index)
        sceneContext.post(.showcaseFeedDataWillUpdate, object: model, sender: self)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        if let index = _cellViewModel?.videoIndex {
            PLog.prepareForReuse(index)
        }
        sceneContext.post(.cellPrepareForReuse, sender: self)
        detachPlayer()
        _cellViewModel = nil
    }
}
