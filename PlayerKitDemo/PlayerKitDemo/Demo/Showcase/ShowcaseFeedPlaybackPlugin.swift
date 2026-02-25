import UIKit
import PlayerKit
import ListKit

@MainActor
protocol ShowcaseFeedPlaybackPluginProtocol: AnyObject {
    var currentPlayingIndex: Int { get }
    var transferringPlayer: Player? { get set }
    func playVideo(at index: Int, in collectionView: UICollectionView, videos: [ShowcaseVideo])
    func pauseCurrent()
    func preRenderAdjacent(currentIndex: Int, videos: [ShowcaseVideo])
    func updatePrefetchWindow(videos: [ShowcaseVideo], focusIndex: Int)
}

@MainActor
protocol ShowcaseFeedAutoPlayPluginProtocol: AnyObject {
    func autoPlayIfNeeded()
}

@MainActor
protocol ShowcaseFeedScrollNextPluginProtocol: AnyObject {
    func scrollToNextPage(from currentIndex: Int)
}

@MainActor
protocol ShowcaseFeedPlayerTransferPluginProtocol: AnyObject {
    func enterDetail(at index: Int, from viewController: UIViewController)
}

@MainActor
final class ShowcaseFeedPlaybackPlugin: NSObject, ListPluginProtocol, ShowcaseFeedPlaybackPluginProtocol, ShowcaseFeedAutoPlayPluginProtocol, ShowcaseFeedScrollNextPluginProtocol, ShowcaseFeedPlayerTransferPluginProtocol {

    struct Configuration {
        var enginePoolMaxCapacity: Int = 6
        var enginePoolMaxPerIdentifier: Int = 5
        var preRenderMaxCount: Int = 4
        var preRenderTimeout: TimeInterval = 10
        var prefetchMaxConcurrent: Int = 4
        var prefetchBytesPerURL: Int64 = 512 * 1024
        var prefetchWindowAhead: Int = 2
        var prefetchWindowBehind: Int = 1

        init() {}
    }

    weak var listContext: ListContext?

    private(set) var currentPlayingIndex: Int = -1
    private weak var currentPlayingCell: ShowcaseFeedCell?
    var transferringPlayer: Player?

    let prefetchManager: ListPrefetchService
    private let preRenderPool = PlayerPreRenderPool.shared

    private let preRenderMaxCount: Int
    private let preRenderTimeout: TimeInterval

    private var pendingScrollTasks: [() -> Void] = []
    private var cellEventObserverIndex: Int = -1
    private var autoPlayRetryCount = 0
    private let maxAutoPlayRetries = 2

    init(configuration: Configuration = Configuration()) {
        // 配置全局引擎池
        PlayerEnginePool.shared.maxCapacity = configuration.enginePoolMaxCapacity
        PlayerEnginePool.shared.maxPerIdentifier = configuration.enginePoolMaxPerIdentifier

        self.preRenderMaxCount = configuration.preRenderMaxCount
        self.preRenderTimeout = configuration.preRenderTimeout

        let prefetchConfig = PreloadConfig(
            maxConcurrent: configuration.prefetchMaxConcurrent,
            bytesPerURL: configuration.prefetchBytesPerURL,
            windowAhead: configuration.prefetchWindowAhead,
            windowBehind: configuration.prefetchWindowBehind
        )
        self.prefetchManager = ListPrefetchPlugin(config: prefetchConfig)
        self.preRenderPool.config = PlayerPreRenderPoolConfig(
            maxCount: configuration.preRenderMaxCount,
            timeout: configuration.preRenderTimeout,
            poolIdentifier: "showcase"
        )

        super.init()
    }

    func implementProtocols() -> [Any.Type] {
        [
            ShowcaseFeedPlaybackPluginProtocol.self,
            ShowcaseFeedAutoPlayPluginProtocol.self,
            ShowcaseFeedScrollNextPluginProtocol.self,
            ShowcaseFeedPlayerTransferPluginProtocol.self,
        ]
    }
    func dependencyProtocols() -> [Any.Type] { [] }

    func listContextDidLoad() {}

    func cleanup() {
        transferringPlayer = nil
        currentPlayingIndex = -1
        currentPlayingCell = nil
        pendingScrollTasks.removeAll()
        autoPlayRetryCount = 0

        cancelAllPreRenders()
        prefetchManager.cancelAll()
    }

    // MARK: - PreRender Pool

    func preRender(url: URL, identifier: String) {
        if preRenderState(for: identifier) != .idle {
            cancelPreRender(identifier: identifier)
        }
        if preRenderPool.count >= preRenderMaxCount {
            evictOldestPreRender()
            if preRenderPool.count >= preRenderMaxCount { return }
        }
        preRenderPool.preRender(url: url, identifier: identifier, extraConfig: nil)
    }

    func cancelPreRender(identifier: String) {
        preRenderPool.cancel(identifier: identifier)
    }

    func cancelAllPreRenders() {
        preRenderPool.cancelAll()
    }

    func consumePreRendered(identifier: String) -> Player? {
        guard let engine = preRenderPool.consume(identifier: identifier) else { return nil }
        guard let enginePlugin = engine as? BasePlugin else { return nil }
        let player = Player(name: "Consumed_\(identifier)")
        player.context.detachInstance(for: PlayerEngineCoreService.self)
        player.context.registerInstance(enginePlugin, protocol: PlayerEngineCoreService.self)
        return player
    }

    func preRenderState(for identifier: String) -> PlayerPreRenderState {
        preRenderPool.state(for: identifier)
    }

    private func evictOldestPreRender() {
        let oldestKey = preRenderPool
            .allEntries()
            .sorted { $0.createdAt < $1.createdAt }
            .first?
            .identifier
        guard let oldestKey else { return }
        cancelPreRender(identifier: oldestKey)
    }

    // MARK: - ListProtocol Lifecycle

    func viewDidAppear(byViewController viewController: UIViewController) {
        if currentPlayingIndex >= 0 {
            resumeCurrentPlayback()
        } else {
            autoPlayIfNeeded()
        }
    }

    func viewWillDisappear(byViewController viewController: UIViewController) {
        if transferringPlayer == nil {
            pauseCurrentPlayback()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let page = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
            handlePageChange(to: page)
        }
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let targetPage = Int(round(targetContentOffset.pointee.y / scrollView.bounds.height))
        if targetPage != currentPlayingIndex {
            handlePageChange(to: targetPage)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
        handlePageChange(to: page)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard !pendingScrollTasks.isEmpty else { return }
        let task = pendingScrollTasks.removeFirst()
        task()
    }

    func listDidReloadSectionViewModels(
        _ sectionViewModels: [BaseListSectionViewModel],
        preSectionViewModels: [BaseListSectionViewModel]?
    ) {
        if preSectionViewModels == nil || preSectionViewModels?.isEmpty == true {
            let videos = videosFromContext()
            if !videos.isEmpty {
                preRenderAdjacent(currentIndex: 0, videos: videos)
                updatePrefetchWindow(videos: videos, focusIndex: 0)
            }
            DispatchQueue.main.async { [weak self] in
                self?.autoPlayIfNeeded()
            }
        }
    }

    // MARK: - AutoPlay

    func autoPlayIfNeeded() {
        guard let ctx = listContext else { return }
        guard ctx.isVisible() else { return }
        guard let cv = ctx.scrollView() as? UICollectionView else { return }
        let videos = videosFromContext()
        guard !videos.isEmpty else { return }

        if currentPlayingIndex < 0 {
            playVideo(at: 0, in: cv, videos: videos)
            preRenderAdjacent(currentIndex: 0, videos: videos)
            updatePrefetchWindow(videos: videos, focusIndex: 0)
            listenCellEvents(at: 0, in: cv)
        }
    }

    // MARK: - Page Change

    private func handlePageChange(to page: Int) {
        guard let ctx = listContext else { return }
        guard let cv = ctx.scrollView() as? UICollectionView else { return }
        let videos = videosFromContext()
        let clampedPage = max(0, min(page, videos.count - 1))

        if clampedPage != currentPlayingIndex {
            removeCellEventListeners(at: currentPlayingIndex, in: cv)
            playVideo(at: clampedPage, in: cv, videos: videos)
        }
        listenCellEvents(at: clampedPage, in: cv)

        preRenderAdjacent(currentIndex: clampedPage, videos: videos)
        updatePrefetchWindow(videos: videos, focusIndex: clampedPage)

        if let vm = ctx.listViewModel() as? ShowcaseFeedListViewModel {
            vm.loadMoreIfNeeded(currentIndex: clampedPage)
        }
    }

    // MARK: - ScrollNext

    func scrollToNextPage(from currentIndex: Int) {
        guard let ctx = listContext else { return }
        guard let vm = ctx.listViewModel() else { return }
        let nextIndex = currentIndex + 1
        let sectionVMs = vm.sectionViewModelsArray
        guard nextIndex < sectionVMs.count else { return }

        pendingScrollTasks.append { [weak self] in
            guard let self = self else { return }
            self.handlePageChange(to: nextIndex)
        }

        ctx.scrollToSectionViewModel(
            sectionVMs[nextIndex],
            scrollPosition: .centeredVertically,
            animated: true
        )
    }

    // MARK: - PlayerTransfer

    func enterDetail(at index: Int, from viewController: UIViewController) {
        guard let ctx = listContext else { return }
        let videos = videosFromContext()
        guard index >= 0, index < videos.count else { return }

        guard let vm = ctx.listViewModel() else { return }
        let sectionVMs = vm.sectionViewModelsArray
        guard index < sectionVMs.count else { return }
        guard let sc = ctx.sectionController(forSectionViewModel: sectionVMs[index]) else { return }
        guard let cell = sc.cell(atIndex: 0) as? ShowcaseFeedCell else { return }
        guard let player = cell.scenePlayer.player else { return }
        guard cell.canDetachPlayer() else { return }

        cell.isTransferringPlayer = true
        cell.detachPlayer()
        transferringPlayer = player
        let transferIndex = index

        let detailVC = ShowcaseDetailViewController()
        detailVC.video = videos[index]
        detailVC.videoIndex = index
        detailVC.player = player
        detailVC.allVideos = videos
        detailVC.onWillDismiss = { [weak self] in
            guard let self = self, let ctx = self.listContext else { return }
            self.transferringPlayer = nil

            guard let vm = ctx.listViewModel() else { return }
            let sectionVMs = vm.sectionViewModelsArray
            if transferIndex < sectionVMs.count {
                if let sc = ctx.sectionController(forSectionViewModel: sectionVMs[transferIndex]),
                   let feedCell = sc.cell(atIndex: 0) as? ShowcaseFeedCell {
                    feedCell.attachTransferredPlayer(player)
                }
            }
        }
        detailVC.onDismiss = nil

        detailVC.modalPresentationStyle = .fullScreen
        viewController.present(detailVC, animated: true)
    }

    // MARK: - Cell Event Listening

    private func listenCellEvents(at index: Int, in collectionView: UICollectionView) {
        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell else { return }
        cellEventObserverIndex = index

        cell.scenePlayer.context.add(self, event: .showcaseOverlayDidTapDetail) { [weak self] object, _ in
            guard let self = self, let ctx = self.listContext else { return }
            if let idx = object as? Int, let vc = ctx.baseListViewController() {
                self.enterDetail(at: idx, from: vc)
            }
        }
        cell.scenePlayer.context.add(self, event: .showcaseAutoPlayNextRequest) { [weak self] object, _ in
            guard let self = self else { return }
            if let currentIdx = object as? Int {
                self.scrollToNextPage(from: currentIdx)
            }
        }
    }

    private func removeCellEventListeners(at index: Int, in collectionView: UICollectionView) {
        guard index >= 0 else { return }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell else { return }
        cell.scenePlayer.context.removeHandlers(forObserver: self)
    }

    // MARK: - Playback

    func playVideo(at index: Int, in collectionView: UICollectionView, videos: [ShowcaseVideo]) {
        guard index >= 0, index < videos.count else { return }
        guard videos[index].url != nil else { return }


        if currentPlayingIndex >= 0, currentPlayingIndex != index {
            stopCell(at: currentPlayingIndex)
        }

        currentPlayingIndex = index

        let targetCell = collectionView.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell
        guard let targetCell = targetCell else {
            if autoPlayRetryCount < maxAutoPlayRetries {
                autoPlayRetryCount += 1
                currentPlayingIndex = -1
                DispatchQueue.main.async { [weak self] in
                    self?.autoPlayIfNeeded()
                }
            }
            return
        }

        autoPlayRetryCount = 0
        currentPlayingCell = targetCell

        targetCell.startPlay(
            isAutoPlay: true,
            video: videos[index],
            index: index,
            playbackPlugin: self
        )

        if let autoPlayPlugin = targetCell.scenePlayer.autoPlayNextService {
            let autoPlayConfig = ShowcaseAutoPlayNextConfigModel(totalCount: videos.count, isEnabled: true)
            (autoPlayPlugin as? BasePlugin)?.configModel = autoPlayConfig
        }
    }

    func pauseCurrent() {
        guard currentPlayingIndex >= 0 else { return }
        stopCell(at: currentPlayingIndex)
    }

    private func pauseCurrentPlayback() {
        currentPlayingCell?.scenePlayer.player?.pause()
    }

    private func resumeCurrentPlayback() {
        currentPlayingCell?.scenePlayer.player?.engineService?.play()
    }

    // MARK: - PreRender Adjacent

    func preRenderAdjacent(currentIndex: Int, videos: [ShowcaseVideo]) {
        let keepRange = (currentIndex - 2)...(currentIndex + 2)
        var keepFeedIds = Set<String>()
        for idx in keepRange {
            guard idx >= 0, idx < videos.count else { continue }
            keepFeedIds.insert(videos[idx].feedId)
        }
        for entry in preRenderPool.allEntries() where !keepFeedIds.contains(entry.identifier) {
            cancelPreRender(identifier: entry.identifier)
        }
        for offset in [-1, 1, -2, 2] {
            let idx = currentIndex + offset
            guard idx >= 0, idx < videos.count else { continue }
            let video = videos[idx]
            guard let url = video.url else { continue }
            let identifier = video.feedId
            let state = preRenderState(for: identifier)
            if state != .idle { continue }
            preRender(url: url, identifier: identifier)
        }
    }

    // MARK: - Prefetch

    func updatePrefetchWindow(videos: [ShowcaseVideo], focusIndex: Int) {
        let indexedURLs = videos.enumerated().compactMap { index, video -> (Int, URL)? in
            guard let url = video.url else { return nil }
            return (index, url)
        }
        guard !indexedURLs.isEmpty else {
            prefetchManager.cancelAll()
            return
        }

        let urls = indexedURLs.map { $0.1 }
        let mappedFocusIndex: Int
        if let exact = indexedURLs.firstIndex(where: { $0.0 == focusIndex }) {
            mappedFocusIndex = exact
        } else if let nearestBefore = indexedURLs.lastIndex(where: { $0.0 < focusIndex }) {
            mappedFocusIndex = nearestBefore
        } else {
            mappedFocusIndex = 0
        }

        prefetchManager.updateWindow(urls: urls, focusIndex: mappedFocusIndex)

        if mappedFocusIndex >= 0, mappedFocusIndex < urls.count {
            prefetchManager.prioritize(url: urls[mappedFocusIndex])
        }
    }

    // MARK: - Helpers

    private func videosFromContext() -> [ShowcaseVideo] {
        guard let vm = listContext?.listViewModel() as? ShowcaseFeedListViewModel else { return [] }
        return vm.videos
    }

    private func stopCell(at index: Int) {
        guard let ctx = listContext else { return }
        guard let cv = ctx.scrollView() as? UICollectionView else { return }
        if let cell = cv.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell {
            cell.scenePlayer.player?.pause()
            if currentPlayingCell === cell {
                currentPlayingCell = nil
            }
            return
        }
        if currentPlayingCell?.videoIndex == index {
            currentPlayingCell?.stopAndRecycleEngine()
            currentPlayingCell = nil
        }
    }
}
