import UIKit
import AVFoundation
import PlayerKit
import ListKit

@MainActor
final class ShowcasePlaybackRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        registerSet.addEntry(pluginClass: PlayerEnginePoolPlugin.self, serviceType: PlayerEnginePoolService.self)
        registerSet.addEntry(pluginClass: PlayerPreRenderManagerPlugin.self, serviceType: PlayerPreRenderManagerService.self)
        registerSet.addEntry(pluginClass: PlayerPrefetchPlugin.self, serviceType: PlayerPrefetchService.self)
    }
}

@MainActor
protocol ShowcaseFeedPlaybackPluginProtocol: AnyObject {
    var currentPlayingIndex: Int { get }
    var typedPlayers: [Int: FeedPlayer] { get }
    var transferringPlayer: FeedPlayer? { get set }
    var enginePool: PlayerEnginePoolService { get }
    var preRenderManager: PlayerPreRenderManagerService { get }
    func playVideo(at index: Int, in collectionView: UICollectionView, videos: [ShowcaseVideo])
    func pauseCurrent()
    func removePlayer(at index: Int)
    func restorePlayer(_ player: FeedPlayer, at index: Int)
    func evictDistantPlayers(in collectionView: UICollectionView)
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
        var prefetchWindowAhead: Int = 3
        var prefetchWindowBehind: Int = 1

        init() {}
    }

    weak var listContext: ListContext?

    private(set) var currentPlayingIndex: Int = -1
    private(set) var typedPlayers: [Int: FeedPlayer] = [:]
    var transferringPlayer: FeedPlayer?

    let enginePool: PlayerEnginePoolService
    let preRenderManager: PlayerPreRenderManagerService
    let prefetchManager: PlayerPrefetchService

    private let keepDistance = 3
    private let poolIdentifier = "showcase"
    private var pendingScrollTasks: [() -> Void] = []
    private var cellEventObserverIndex: Int = -1
    private var autoPlayRetryCount = 0
    private let maxAutoPlayRetries = 2

    init(configuration: Configuration = Configuration()) {
        let ctx = Context(name: "ShowcasePlaybackServices")

        let provider = ShowcasePlaybackRegProvider()
        ctx.addRegProvider(provider)

        guard let pool = ctx.resolveService(PlayerEnginePoolService.self),
              let preRender = ctx.resolveService(PlayerPreRenderManagerService.self),
              let prefetch = ctx.resolveService(PlayerPrefetchService.self) else {
            fatalError("Services not properly initialized")
        }

        pool.maxCapacity = configuration.enginePoolMaxCapacity
        pool.maxPerIdentifier = configuration.enginePoolMaxPerIdentifier

        preRender.maxPreRenderCount = configuration.preRenderMaxCount
        preRender.preRenderTimeout = configuration.preRenderTimeout
        let preRenderConfig = PlayerPreRenderManagerConfigModel(enginePool: pool, poolIdentifier: "showcase")
        ctx.configPlugin(serviceProtocol: PlayerPreRenderManagerService.self, withModel: preRenderConfig)

        if let prefetchPlugin = prefetch as? PlayerPrefetchPlugin {
            prefetchPlugin.prefetchConfig = PreloadConfig(
                maxConcurrent: configuration.prefetchMaxConcurrent,
                bytesPerURL: configuration.prefetchBytesPerURL,
                windowAhead: configuration.prefetchWindowAhead,
                windowBehind: configuration.prefetchWindowBehind
            )
        }

        self.enginePool = pool
        self.preRenderManager = preRender
        self.prefetchManager = prefetch
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
        for (_, player) in typedPlayers {
            player.destroyPlayer()
            player.cleanup()
        }
        typedPlayers.removeAll()
        transferringPlayer = nil
        currentPlayingIndex = -1
        pendingScrollTasks.removeAll()
        autoPlayRetryCount = 0

        preRenderManager.cancelAll()
        prefetchManager.cancelAll()
        enginePool.clear()
    }

    // MARK: - ListProtocol Lifecycle

    func viewDidAppear(byViewController viewController: UIViewController) {
        autoPlayIfNeeded()
    }

    func viewWillDisappear(byViewController viewController: UIViewController) {
        if transferringPlayer == nil {
            pauseCurrent()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            let page = Int(round(scrollView.contentOffset.y / scrollView.bounds.height))
            handlePageChange(to: page)
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

        evictDistantPlayers(in: cv)
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
        guard let feedPlayer = cell.feedPlayer else { return }

        cell.detachPlayer()
        removePlayer(at: index)
        transferringPlayer = feedPlayer
        let transferIndex = index

        let detailVC = ShowcaseDetailViewController()
        detailVC.video = videos[index]
        detailVC.videoIndex = index
        detailVC.feedPlayer = feedPlayer
        detailVC.allVideos = videos
        detailVC.onWillDismiss = { [weak self] in
            guard let self = self, let ctx = self.listContext else { return }
            self.restorePlayer(feedPlayer, at: transferIndex)
            self.transferringPlayer = nil

            guard let vm = ctx.listViewModel() else { return }
            let sectionVMs = vm.sectionViewModelsArray
            if transferIndex < sectionVMs.count {
                if let sc = ctx.sectionController(forSectionViewModel: sectionVMs[transferIndex]),
                   let feedCell = sc.cell(atIndex: 0) as? ShowcaseFeedCell {
                    feedCell.addTypedPlayerIfNeeded(feedPlayer)
                    feedCell.attachPlayerView()
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

        cell.sceneContext.context.add(self, event: .showcaseOverlayDidTapDetail) { [weak self] object, _ in
            guard let self = self, let ctx = self.listContext else { return }
            if let idx = object as? Int, let vc = ctx.baseListViewController() {
                self.enterDetail(at: idx, from: vc)
            }
        }
        cell.sceneContext.context.add(self, event: .showcaseAutoPlayNextRequest) { [weak self] object, _ in
            guard let self = self else { return }
            if let currentIdx = object as? Int {
                self.scrollToNextPage(from: currentIdx)
            }
        }
    }

    private func removeCellEventListeners(at index: Int, in collectionView: UICollectionView) {
        guard index >= 0 else { return }
        guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell else { return }
        cell.sceneContext.context.removeHandlers(forObserver: self)
    }

    // MARK: - Playback

    func playVideo(at index: Int, in collectionView: UICollectionView, videos: [ShowcaseVideo]) {
        guard index >= 0, index < videos.count else { return }
        guard videos[index].url != nil else { return }
        let video = videos[index]

        PLog.scrollPlay(index)

        if currentPlayingIndex >= 0, currentPlayingIndex != index {
            typedPlayers[currentPlayingIndex]?.pause()
        }

        currentPlayingIndex = index

        let targetCell = collectionView.cellForItem(at: IndexPath(item: 0, section: index)) as? ShowcaseFeedCell
        guard let processService = targetCell?.sceneContext.context.resolveService(PlayerScenePlayerProcessService.self) else {
            // Cell not yet available (layout timing race). Retry once on next run loop.
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

        processService.execPlay(
            isAutoPlay: true,
            prepare: nil,
            createIfNeeded: { [weak self] in
                guard let self = self else { return }
                let feedPlayer = self.obtainTypedPlayer(for: index, videos: videos)
                targetCell?.addTypedPlayerIfNeeded(feedPlayer)
            },
            attach: {
                targetCell?.attachPlayerView()
            },
            checkDataValid: {
                return targetCell?.checkDataValid(video: video) ?? false
            },
            setDataIfNeeded: {
                targetCell?.setDataIfNeeded(video: video, index: index)
            }
        )

        if let autoPlayPlugin = targetCell?.sceneContext.context.resolveService(ShowcaseAutoPlayNextService.self) {
            let autoPlayConfig = ShowcaseAutoPlayNextConfigModel(totalCount: videos.count, isEnabled: true)
            (autoPlayPlugin as? BasePlugin)?.configModel = autoPlayConfig
        }
    }

    func pauseCurrent() {
        guard currentPlayingIndex >= 0 else { return }
        typedPlayers[currentPlayingIndex]?.pause()
    }

    func removePlayer(at index: Int) {
        typedPlayers.removeValue(forKey: index)
    }

    func restorePlayer(_ player: FeedPlayer, at index: Int) {
        typedPlayers[index] = player
    }

    // MARK: - Obtain

    private func obtainTypedPlayer(for index: Int, videos: [ShowcaseVideo]) -> FeedPlayer {
        if let existing = typedPlayers[index] {
            PLog.obtain(index, source: "existing", poolCount: enginePool.count, playersAlive: Array(typedPlayers.keys))
            return existing
        }

        let preRenderId = "showcase_\(index)"
        if let preRenderedPlayer = preRenderManager.consumePreRendered(identifier: preRenderId) {
            let config = FeedPlayerConfiguration()
            config.autoPlay = false
            config.looping = false
            let feedPlayer = FeedPlayer(adoptingPlayer: preRenderedPlayer, configuration: config)
            feedPlayer.bindPool(enginePool, identifier: poolIdentifier)
            typedPlayers[index] = feedPlayer
            PLog.obtain(index, source: "preRendered", poolCount: enginePool.count, playersAlive: Array(typedPlayers.keys))
            return feedPlayer
        }

        if let takenPlayer = preRenderManager.takePlayer(identifier: preRenderId) {
            let config = FeedPlayerConfiguration()
            config.autoPlay = false
            config.looping = false
            let feedPlayer = FeedPlayer(adoptingPlayer: takenPlayer, configuration: config)
            feedPlayer.bindPool(enginePool, identifier: poolIdentifier)
            typedPlayers[index] = feedPlayer
            PLog.obtain(index, source: "taken_preparing", poolCount: enginePool.count, playersAlive: Array(typedPlayers.keys))
            return feedPlayer
        }

        let config = FeedPlayerConfiguration()
        config.autoPlay = false
        config.looping = false
        let feedPlayer = FeedPlayer(configuration: config)
        feedPlayer.bindPool(enginePool, identifier: poolIdentifier)
        feedPlayer.acquireEngine()
        typedPlayers[index] = feedPlayer
        PLog.obtain(index, source: "new", poolCount: enginePool.count, playersAlive: Array(typedPlayers.keys))
        return feedPlayer
    }

    // MARK: - Eviction

    func evictDistantPlayers(in collectionView: UICollectionView) {
        let lo = currentPlayingIndex - keepDistance
        let hi = currentPlayingIndex + keepDistance
        var evicted: [Int] = []
        for idx in Array(typedPlayers.keys) where idx < lo || idx > hi {
            guard let feedPlayer = typedPlayers.removeValue(forKey: idx) else { continue }
            if let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: idx)) as? ShowcaseFeedCell,
               cell.feedPlayer === feedPlayer {
                cell.detachPlayer()
            }
            feedPlayer.recycleEngine()
            evicted.append(idx)
        }
        PLog.evict(evicted, poolCountAfter: enginePool.count)
    }

    // MARK: - PreRender Adjacent

    func preRenderAdjacent(currentIndex: Int, videos: [ShowcaseVideo]) {
        let keepRange = (currentIndex - 2)...(currentIndex + 2)
        for entry in preRenderManager.activeEntries {
            let id = entry.identifier
            if let idxStr = id.split(separator: "_").last, let idx = Int(idxStr) {
                if !keepRange.contains(idx) {
                    preRenderManager.cancelPreRender(identifier: id)
                }
            }
        }

        for offset in [-1, 1, -2, 2] {
            let idx = currentIndex + offset
            guard idx >= 0, idx < videos.count else { continue }
            guard typedPlayers[idx] == nil else { continue }
            guard let url = videos[idx].url else { continue }
            let identifier = "showcase_\(idx)"
            let state = preRenderManager.state(for: identifier)
            if state != .idle && state != .cancelled && state != .expired && state != .failed { continue }
            preRenderManager.preRender(url: url, identifier: identifier)
        }
    }

    // MARK: - Prefetch

    func updatePrefetchWindow(videos: [ShowcaseVideo], focusIndex: Int) {
        let urls = videos.compactMap { $0.url }
        prefetchManager.updateWindow(urls: urls, focusIndex: focusIndex)
        if focusIndex >= 0, focusIndex < videos.count, let url = videos[focusIndex].url {
            prefetchManager.prioritize(url: url)
        }
    }

    // MARK: - Helpers

    private func videosFromContext() -> [ShowcaseVideo] {
        guard let vm = listContext?.listViewModel() as? ShowcaseFeedListViewModel else { return [] }
        return vm.videos
    }
}
