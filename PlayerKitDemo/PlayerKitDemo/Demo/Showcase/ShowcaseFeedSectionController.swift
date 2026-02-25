import UIKit
import IGListKit
import PlayerKit
import ListKit

@MainActor
protocol FeedAutoPlayProtocol: AnyObject {
    var enablePlayByFeedAutoPlay: Bool { get }
    func startPlayForFeedAutoPlay()
    func finishPlayForFeedAutoPlay()
    var isFeedAutoPlaying: Bool { get }
}

@MainActor
final class ShowcaseFeedSectionController: BaseListSectionController, FeedAutoPlayProtocol, ListSectionControllerWorkingRangeDelegate {

    required init() {
        super.init()
        sectionWorkingRangeDelegate = self
    }

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
        cell.stopAndDetachPlayer()
    }

    var isFeedAutoPlaying: Bool {
        guard let cell = feedCell else { return false }
        guard let engineService = cell.scenePlayer.engineService else { return false }
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

    override func configCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell,
              let cellViewModel = model as? ShowcaseFeedCellViewModel else { return }

        feedCell.bindCellViewModel(cellViewModel)

        if let vm = feedViewModel,
           let plugin = vm.listContext?.responderForProtocol(ShowcaseFeedPlaybackPluginProtocol.self) as? ShowcaseFeedPlaybackPlugin {
            let config = ShowcaseFeedPreRenderConfigModel(
                cancelPreRender: { [weak plugin] identifier in
                    plugin?.cancelPreRender(identifier: identifier)
                }
            )
            feedCell.scenePlayer.context.configPlugin(serviceProtocol: ShowcaseFeedPreRenderService.self, withModel: config)
        }
    }

    /// Cell 显示回调，触发 Cell 的 cellWillDisplay
    override func sectionWillDisplayCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell else { return }
        if let vm = feedViewModel,
           let plugin = vm.listContext?.responderForProtocol(ShowcaseFeedPlaybackPluginProtocol.self) as? ShowcaseFeedPlaybackPlugin {
            feedCell.prepareForDisplay(
                video: vm.video,
                index: vm.videoIndex,
                playbackPlugin: plugin
            )
        }
        feedCell.cellWillDisplay(duplicateReload: false)
    }

    /// Cell 隐藏回调，触发 Cell 的 cellDidEndDisplaying
    override func sectionDidEndDisplayingCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {
        guard let feedCell = cell as? ShowcaseFeedCell else { return }
        feedCell.cellDidEndDisplaying(duplicateReload: false)
    }

    func sectionControllerWillEnterWorkingRange(_ sectionController: BaseListSectionController) {
        guard sectionController === self else { return }
        guard let feedCell = feedCell else { return }
        if let vm = feedViewModel,
           let plugin = vm.listContext?.responderForProtocol(ShowcaseFeedPlaybackPluginProtocol.self) as? ShowcaseFeedPlaybackPlugin {
            plugin.preRenderAdjacent(currentIndex: vm.videoIndex, videos: videosFromContext())

            let config = ShowcaseFeedPreRenderConfigModel(
                cancelPreRender: { [weak plugin] identifier in
                    plugin?.cancelPreRender(identifier: identifier)
                }
            )
            feedCell.scenePlayer.context.configPlugin(serviceProtocol: ShowcaseFeedPreRenderService.self, withModel: config)
        }
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
