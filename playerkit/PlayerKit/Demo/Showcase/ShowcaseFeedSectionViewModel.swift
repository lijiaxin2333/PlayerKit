import UIKit
import IGListKit

@MainActor
final class ShowcaseFeedSectionViewModel: BaseListSectionViewModel {

    let video: ShowcaseVideo
    let videoIndex: Int

    /// CellViewModel，遵循 ListKit 标准模式
    private var _cellViewModel: ShowcaseFeedCellViewModel?

    var cellViewModel: ShowcaseFeedCellViewModel {
        if let vm = _cellViewModel {
            return vm
        }
        let vm = ShowcaseFeedCellViewModel(video: video, index: videoIndex)
        vm.bindSectionViewModel(self)
        _cellViewModel = vm
        // 设置 modelsArray
        appendModels([vm as AnyObject], animated: false)
        return vm
    }

    init(video: ShowcaseVideo, index: Int) {
        self.video = video
        self.videoIndex = index
        super.init(modelsArray: [])
    }

    @available(*, unavailable)
    override init(modelsArray: [AnyObject] = []) {
        fatalError()
    }

    override class func sectionControllerClass() -> BaseListSectionController.Type? {
        ShowcaseFeedSectionController.self
    }

    // MARK: - Factory Methods

    override class func canHandleData(_ data: Any?) -> Bool {
        data is ShowcaseFeedSectionData
    }

    override class func sectionViewModel(forData data: Any, context: ListContext) -> Self {
        guard let sectionData = data as? ShowcaseFeedSectionData else {
            fatalError("ShowcaseFeedSectionViewModel requires ShowcaseFeedSectionData")
        }
        let vm = ShowcaseFeedSectionViewModel(video: sectionData.video, index: sectionData.index)
        vm.updateListContext(context)
        return vm as! Self
    }

    override func diffIdentifier() -> any NSObjectProtocol {
        video.feedId as NSString
    }

    override func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        guard let other = object as? ShowcaseFeedSectionViewModel else { return false }
        return video.feedId == other.video.feedId
    }
}
