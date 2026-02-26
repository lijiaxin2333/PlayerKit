import UIKit
import ListKit

/// Showcase Feed Cell 的 ViewModel
/// 遵循 ListCellViewModelProtocol，负责列表层的数据管理
@MainActor
final class ShowcaseFeedCellViewModel: BaseListCellViewModel<ShowcaseVideo> {

    private(set) var video: ShowcaseVideo
    private(set) var videoIndex: Int

    init(video: ShowcaseVideo, index: Int) {
        self.video = video
        self.videoIndex = index
        // 先用空参数初始化，后续通过 bindSectionViewModel 关联
        super.init(cellData: video, listContext: nil, sectionViewModel: BaseListSectionViewModel.placeholder)
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

// MARK: - BaseListSectionViewModel Placeholder

private extension BaseListSectionViewModel {
    /// 占位用，避免 init 时传入无效参数
    static var placeholder: BaseListSectionViewModel {
        BaseListSectionViewModel(modelsArray: [])
    }
}
