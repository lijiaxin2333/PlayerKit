import UIKit
import IGListKit

// MARK: - IGListDisplayDelegate

/// IGListKit 显示事件代理实现
/// 将 Section/Cell 的显示/隐藏事件转发给代理
extension BaseListSectionController: IGListKit.ListDisplayDelegate {

    /// Section 即将显示
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerWillDisplay(self)
    }

    /// Section 已移出屏幕
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerDidEndDisplaying(self)
    }

    /// Cell 即将显示
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionWillDisplayCell(cell, index: index, model: modelsArray[index])
    }

    /// Cell 已移出屏幕
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionDidEndDisplayingCell(cell, index: index, model: modelsArray[index])
    }
}
