import UIKit
import PlayerKit
import ListKit

/// Showcase Feed Cell
/// 实现 ListCellProtocol，遵循 ListKit 标准模式
/// 播放器相关逻辑通过 scenePlayer + Plugin 架构处理
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

        let player = scenePlayer.createPlayer(prerenderKey: nil)
        scenePlayer.addPlayer(player)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Player Methods

    func addPlayerIfNeeded(_ player: Player) {
        scenePlayer.addPlayer(player)
    }

    func startPlay(
        isAutoPlay: Bool,
        video: ShowcaseVideo,
        index: Int,
        playbackPlugin: ShowcaseFeedPlaybackPlugin
    ) {
        scenePlayer.player?.bindPool(identifier: "showcase")
        guard let processService = scenePlayer.processService else { return }
        processService.execPlay(
            isAutoPlay: isAutoPlay,
            prepare: nil,
            createIfNeeded: { [weak self] in
                guard let self = self else { return }
                self.preparePlayerIfNeeded(video: video, index: index, playbackPlugin: playbackPlugin)
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

    private func preparePlayerIfNeeded(
        video: ShowcaseVideo,
        index: Int,
        playbackPlugin: ShowcaseFeedPlaybackPlugin
    ) {
        guard let player = scenePlayer.player else { return }
        if player.engineService?.avPlayer?.currentItem != nil { return }

        let identifier = "showcase_\(index)"
        if let preRenderedPlayer = playbackPlugin.consumePreRendered(identifier: identifier),
           preRenderedPlayer.engineService?.currentURL == video.url {
            player.adoptEngine(from: preRenderedPlayer)
            // 预渲染引擎的 isLooping=true，正式播放需要恢复为 false
            player.engineService?.isLooping = false
            return
        }

        playbackPlugin.cancelPreRender(identifier: identifier)
        _ = player.acquireEngine()
    }

    func attachPlayerView() {
        guard let player = scenePlayer.player else { return }
        guard let pv = player.playerView else { return }
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
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
        scenePlayer.removePlayer()
    }

    func stopAndDetachPlayer() {
        guard let player = scenePlayer.player else { return }
        player.pause()
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    func stopAndRecycleEngine() {
        guard let player = scenePlayer.player else { return }
        player.pause()
        player.engineService?.stop()
        player.recycleEngine()
        _playerContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    func stopAndRemovePlayer() {
        stopAndRecycleEngine()
        scenePlayer.removePlayer()
    }

    func canDetachPlayer() -> Bool {
        guard let player = scenePlayer.player else { return false }
        guard player.engineService != nil else { return false }
        return scenePlayer.playbackControl?.isPlaying == true
    }

    func attachTransferredPlayer(_ player: Player) {
        isTransferringPlayer = false
        addPlayerIfNeeded(player)
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
        scenePlayer.post(.cellPrepareForReuse, sender: self)
        stopAndRecycleEngine()
        if !scenePlayer.hasPlayer() {
            let player = scenePlayer.createPlayer(prerenderKey: nil)
            scenePlayer.addPlayer(player)
        }
        _cellViewModel = nil
    }
}
