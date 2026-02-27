import UIKit
import IGListKit
import MixedListKit

@MainActor
final class ShowcaseFeedSectionViewModel: BaseListSectionViewModel {

    let video: ShowcaseVideo
    let videoIndex: Int

    /// 便捷访问 CellViewModel（从 modelsArray 获取）
    var cellViewModel: ShowcaseFeedCellViewModel {
        modelsArray.first as! ShowcaseFeedCellViewModel
    }

    init(video: ShowcaseVideo, index: Int) {
        self.video = video
        self.videoIndex = index

        // 创建 CellViewModel（sectionViewModel 先传 nil，因为 Swift 两阶段初始化限制）
        let vm = ShowcaseFeedCellViewModel(video: video, index: index, sectionViewModel: nil)

        super.init(modelsArray: [vm as AnyObject])

        // 绑定 SectionViewModel
        vm.bindSectionViewModel(self)
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
