import IGListKit

// MARK: - IGListWorkingRangeDelegate

extension BaseListSectionController: IGListKit.ListWorkingRangeDelegate {

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerWillEnterWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerWillEnterWorkingRange(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerDidExitWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerDidExitWorkingRange(self)
    }
}
