import UIKit
import IGListKit

// MARK: - IGListDisplayDelegate

extension BaseListSectionController: IGListKit.ListDisplayDelegate {

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerWillDisplay(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerDidEndDisplaying(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionWillDisplayCell(cell, index: index, model: modelsArray[index])
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionDidEndDisplayingCell(cell, index: index, model: modelsArray[index])
    }
}
