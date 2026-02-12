import UIKit
import IGListKit

@MainActor
protocol FeedAutoPlayProtocol: AnyObject {
    var enablePlayByFeedAutoPlay: Bool { get }
    func startPlayForFeedAutoPlay()
    func finishPlayForFeedAutoPlay()
    var isFeedAutoPlaying: Bool { get }
}

@MainActor
final class ShowcaseFeedSectionController: BaseListSectionController, FeedAutoPlayProtocol {

    private var feedViewModel: ShowcaseFeedSectionViewModel? {
        viewModel as? ShowcaseFeedSectionViewModel
    }

    private var feedCell: ShowcaseFeedCell? {
        cell(atIndex: 0) as? ShowcaseFeedCell
    }

    // MARK: - FeedAutoPlayProtocol

    var enablePlayByFeedAutoPlay: Bool {
        guard let vm = feedViewModel else { return false }
        return vm.video.url != nil
    }

    func startPlayForFeedAutoPlay() {
        guard let vm = feedViewModel,
              let plugin: ShowcaseFeedPlaybackPluginProtocol = vm.listContext?.responderForProtocol(ShowcaseFeedPlaybackPluginProtocol.self),
              let cv = vm.listContext?.scrollView() as? UICollectionView else { return }
        plugin.playVideo(at: vm.videoIndex, in: cv, videos: videosFromContext())
    }

    func finishPlayForFeedAutoPlay() {
        guard let cell = feedCell else { return }
        cell.detachPlayer()
    }

    var isFeedAutoPlaying: Bool {
        guard let cell = feedCell else { return false }
        guard let engineService = cell.sceneContext.context.resolveService(PlayerEngineCoreService.self) else { return false }
        return engineService.playbackState == .playing
    }

    // MARK: - Override

    override func didBindSectionViewModel() {
        super.didBindSectionViewModel()
        // 触发 cellViewModel 初始化，确保 modelsArray 被设置
        _ = feedViewModel?.cellViewModel
    }

    override func cellClass() -> AnyClass? {
        ShowcaseFeedCell.self
    }

    override func sizeForItem(atIndex index: Int, model: AnyObject, collectionViewSize: CGSize) -> CGSize {
        collectionViewSize
    }

    /// 使用 ListKit 标准模式：通过 CellViewModel 绑定数据
    override func configCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell,
              let cellViewModel = model as? ShowcaseFeedCellViewModel else { return }

        // 绑定 CellViewModel（标准 ListKit 模式）
        feedCell.bindCellViewModel(cellViewModel)

        // 配置 PreRender（播放器层）
        if let vm = feedViewModel,
           let plugin: ShowcaseFeedPlaybackPluginProtocol = vm.listContext?.responderForProtocol(ShowcaseFeedPlaybackPluginProtocol.self) {
            let preRenderConfig = ShowcaseFeedPreRenderConfigModel(playbackPlugin: plugin)
            feedCell.sceneContext.configComp(serviceProtocol: ShowcaseFeedPreRenderService.self, withModel: preRenderConfig)
        }
    }

    /// Cell 显示回调，触发 Cell 的 cellWillDisplay
    override func sectionWillDisplayCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell else { return }
        feedCell.cellWillDisplay(duplicateReload: false)
    }

    /// Cell 隐藏回调，触发 Cell 的 cellDidEndDisplaying
    override func sectionDidEndDisplayingCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell else { return }
        feedCell.cellDidEndDisplaying(duplicateReload: false)
    }

    override func didSelectItem(atIndex index: Int, model: AnyObject) {}

    override func sectionBackgroundColor() -> UIColor? { .black }

    override func showSeparator() -> Bool { false }

    private func videosFromContext() -> [ShowcaseVideo] {
        guard let vm = feedViewModel,
              let listVM = vm.listContext?.listViewModel() as? ShowcaseFeedListViewModel else { return [] }
        return listVM.videos
    }
}
