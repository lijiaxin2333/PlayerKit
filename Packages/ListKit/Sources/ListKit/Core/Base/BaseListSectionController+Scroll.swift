import IGListKit

// MARK: - IGListScrollDelegate

extension BaseListSectionController: IGListKit.ListScrollDelegate {

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didScroll sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidScroll(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willBeginDragging sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerWillBeginDragging(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDragging sectionController: IGListKit.ListSectionController, willDecelerate decelerate: Bool) {
        sectionScrollDelegate?.sectionControllerDidEndDragging(self, willDecelerate: decelerate)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDeceleratingSectionController sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidEndDecelerating(self)
    }
}
