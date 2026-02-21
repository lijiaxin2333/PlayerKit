import UIKit
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
    private var hasAppear = false
    var isTransferringPlayer = false

    /// 绑定 CellViewModel
    func bindCellViewModel(_ cellViewModel: ListCellViewModelProtocol) {
        guard let vm = cellViewModel as? ShowcaseFeedCellViewModel else { return }
        _cellViewModel = vm

        configSceneData(video: vm.video, index: vm.videoIndex)
    }

    /// 获取当前绑定的 CellViewModel
    func cellViewModel() -> ListCellViewModelProtocol? {
        _cellViewModel
    }

    /// Cell 即将显示
    func cellWillDisplay(duplicateReload: Bool) {
        if hasAppear { return }
        hasAppear = true
        scenePlayer.post(.cellWillDisplay, sender: self)
    }

    func cellDidEndDisplaying(duplicateReload: Bool) {
        if !hasAppear { return }
        hasAppear = false
        scenePlayer.post(.cellDidEndDisplaying, sender: self)
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

    let scenePlayer = ShowcaseFeedScenePlayer()
    private let _playerContainer = UIView()

    var feedPlayer: FeedPlayer? { scenePlayer.feedPlayer }

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

        let cellViewConfig = ShowcaseFeedCellViewConfigModel(contentView: contentView, playerContainer: _playerContainer)
        scenePlayer.post(.showcaseFeedCellViewDidSet, object: cellViewConfig, sender: self)

        let typedPlayer = scenePlayer.createTypedPlayer(prerenderKey: nil)
        scenePlayer.addTypedPlayer(typedPlayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Player Methods

    func addTypedPlayerIfNeeded(_ typedPlayer: FeedPlayer) {
        scenePlayer.addTypedPlayer(typedPlayer)
    }

    func startPlay(
        isAutoPlay: Bool,
        video: ShowcaseVideo,
        index: Int,
        playbackPlugin: ShowcaseFeedPlaybackPluginProtocol
    ) {
        scenePlayer.feedPlayer?.bindPool(playbackPlugin.enginePool, identifier: "showcase")
        guard let processService = scenePlayer.resolveService(PlayerScenePlayerProcessService.self) else { return }
        processService.execPlay(
            isAutoPlay: isAutoPlay,
            prepare: nil,
            createIfNeeded: { [weak self] in
                guard let self = self else { return }
                self.prepareTypedPlayerIfNeeded(video: video, index: index, playbackPlugin: playbackPlugin)
            },
            attach: { [weak self] in
                self?.attachPlayerView()
            },
            checkDataValid: { [weak self] in
                self?.checkDataValid(video: video) ?? false
            },
            setDataIfNeeded: { [weak self] in
                self?.setDataIfNeeded(video: video, index: index)
            }
        )
    }

    private func prepareTypedPlayerIfNeeded(
        video: ShowcaseVideo,
        index: Int,
        playbackPlugin: ShowcaseFeedPlaybackPluginProtocol
    ) {
        guard let feedPlayer = scenePlayer.feedPlayer else { return }
        if feedPlayer.engineService?.avPlayer?.currentItem != nil { return }

        let identifier = "showcase_\(index)"
        if let preRenderedPlayer = playbackPlugin.preRenderManager.consumePreRendered(identifier: identifier),
           preRenderedPlayer.engineService?.currentURL == video.url {
            feedPlayer.adoptEngine(from: preRenderedPlayer)
            return
        }

        playbackPlugin.preRenderManager.cancelPreRender(identifier: identifier)
        _ = feedPlayer.acquireEngine()
    }

    func attachPlayerView() {
        guard let feedPlayer = scenePlayer.feedPlayer else { return }
        guard let pv = feedPlayer.playerView else { return }
        if pv.superview === _playerContainer { return }
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
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
        scenePlayer.removeTypedPlayer()
    }

    func stopAndDetachPlayer() {
        guard let player = scenePlayer.feedPlayer else { return }
        player.pause()
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    func stopAndRecycleEngine() {
        guard let player = scenePlayer.feedPlayer else { return }
        player.pause()
        player.playbackControlService?.stop()
        player.recycleEngine()
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    func stopAndRemovePlayer() {
        stopAndRecycleEngine()
        scenePlayer.removeTypedPlayer()
    }

    func canDetachPlayer() -> Bool {
        guard let feedPlayer = feedPlayer else { return false }
        guard feedPlayer.engineService != nil else { return false }
        return scenePlayer.resolveService(PlayerPlaybackControlService.self)?.isPlaying == true
    }

    func attachTransferredPlayer(_ player: FeedPlayer) {
        isTransferringPlayer = false
        addTypedPlayerIfNeeded(player)
        attachPlayerView()
    }

    // MARK: - 兼容方法（保持原有调用方式）

    func checkDataValid(video: ShowcaseVideo) -> Bool {
        guard let currentVideo = scenePlayer.dataService?.video else { return false }
        guard currentVideo.feedId == video.feedId else { return false }
        guard scenePlayer.engineService?.currentURL == video.url else { return false }
        return true
    }

    func setDataIfNeeded(video: ShowcaseVideo, index: Int) {
        configSceneData(video: video, index: index)
    }

    private func configSceneData(video: ShowcaseVideo, index: Int) {
        let model = ShowcaseFeedDataConfigModel(video: video, index: index)
        scenePlayer.context.configPlugin(serviceProtocol: ShowcaseFeedDataService.self, withModel: model)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        hasAppear = false
        isTransferringPlayer = false
        if let index = _cellViewModel?.videoIndex {
            PLog.prepareForReuse(index)
        }
        scenePlayer.post(.cellPrepareForReuse, sender: self)
        stopAndRecycleEngine()
        if !scenePlayer.hasTypedPlayer() {
            let typedPlayer = scenePlayer.createTypedPlayer(prerenderKey: nil)
            scenePlayer.addTypedPlayer(typedPlayer)
        }
        _cellViewModel = nil
    }
}
