import UIKit
import ListKit

@MainActor
final class ShowcaseFeedListViewModel: BaseListViewModel {

    var videos: [ShowcaseVideo] = []
    private(set) var isLoadingMore = false
    private var lastLoadMoreTriggeredCount: Int = -1

    var onDataLoaded: ((_ isFirstLoad: Bool) -> Void)?
    var onLoadError: (() -> Void)?

    required init() {
        super.init()
        registerSectionViewModelClass(ShowcaseFeedSectionViewModel.self, description: "ShowcaseFeed")
    }

    override func fetchListData() {
        refreshState = .isLoading
        ShowcaseDataSource.shared.reset()
        ShowcaseDataSource.shared.fetchFeed { [weak self] newVideos, _ in
            guard let self = self else { return }
            self.refreshState = .isNotLoading

            guard !newVideos.isEmpty else {
                self.onLoadError?()
                return
            }

            self.videos = ShowcaseDataSource.shared.videos
            self.buildSectionViewModels { [weak self] in
                self?.onDataLoaded?(true)
            }
        }
    }

    func loadMoreIfNeeded(currentIndex: Int) {
        guard !isLoadingMore else { return }
        guard ShowcaseDataSource.shared.hasMore else { return }
        let total = videos.count
        let remaining = total - currentIndex - 1
        guard remaining < 3, lastLoadMoreTriggeredCount != total else { return }

        lastLoadMoreTriggeredCount = total
        isLoadingMore = true
        loadMoreState = .isLoading

        ShowcaseDataSource.shared.loadMore { [weak self] newVideos, _ in
            guard let self = self else { return }
            self.isLoadingMore = false
            self.loadMoreState = .isNotLoading
            guard !newVideos.isEmpty else { return }

            self.videos = ShowcaseDataSource.shared.videos
            let startIndex = self.videos.count - newVideos.count
            let newViewModels = newVideos.enumerated().compactMap { offset, video -> BaseListSectionViewModel? in
                let data = ShowcaseFeedSectionData(video: video, index: startIndex + offset)
                return self.createSectionViewModel(forData: data)
            }
            self.appendSectionViewModels(newViewModels, animated: false) { [weak self] _ in
                self?.onDataLoaded?(false)
            }
        }
    }

    func reset() {
        videos = []
        sectionViewModelsArray.removeAll()
        isLoadingMore = false
        lastLoadMoreTriggeredCount = -1
    }

    private func buildSectionViewModels(completion: (() -> Void)? = nil) {
        let vms = videos.enumerated().compactMap { index, video -> BaseListSectionViewModel? in
            let data = ShowcaseFeedSectionData(video: video, index: index)
            return createSectionViewModel(forData: data)
        }
        reloadBySectionViewModels(vms) { _ in
            completion?()
        }
    }
}
