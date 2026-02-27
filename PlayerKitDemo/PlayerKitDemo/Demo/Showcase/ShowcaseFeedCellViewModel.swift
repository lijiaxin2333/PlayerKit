import UIKit
import MixedListKit

/// Showcase Feed Cell 的 ViewModel
/// 遵循 ListCellViewModelProtocol，负责列表层的数据管理
@MainActor
final class ShowcaseFeedCellViewModel: BaseListCellViewModel<ShowcaseVideo> {

    private(set) var video: ShowcaseVideo
    private(set) var videoIndex: Int

    /// 初始化
    /// - Parameters:
    ///   - video: 视频数据
    ///   - index: 视频索引
    ///   - sectionViewModel: SectionViewModel（可传 nil，后续通过 bindSectionViewModel 绑定）
    init(video: ShowcaseVideo, index: Int, sectionViewModel: BaseListSectionViewModel?) {
        self.video = video
        self.videoIndex = index
        super.init(cellData: video, listContext: nil, sectionViewModel: sectionViewModel)
    }

    /// 绑定 SectionViewModel（在 SectionViewModel 创建 CellViewModel 后调用）
    func bindSectionViewModel(_ sectionViewModel: BaseListSectionViewModel) {
        updateSectionViewModel(sectionViewModel)
    }

    // MARK: - ListCellViewModelProtocol

    override func cellClass() -> AnyClass {
        ShowcaseFeedCell.self
    }

    override func cellSize() -> CGSize {
        // 全屏尺寸，由 SectionController 决定
        .zero
    }
}
