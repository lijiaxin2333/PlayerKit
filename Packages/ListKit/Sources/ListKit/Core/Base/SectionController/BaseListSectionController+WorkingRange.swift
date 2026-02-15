import IGListKit

// MARK: - IGListWorkingRangeDelegate

/// IGListKit 预加载范围代理实现
/// 将 Section 进入/离开预加载范围的事件转发给代理
extension BaseListSectionController: IGListKit.ListWorkingRangeDelegate {

    /// Section 即将进入预加载范围
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerWillEnterWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerWillEnterWorkingRange(self)
    }

    /// Section 已离开预加载范围
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerDidExitWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerDidExitWorkingRange(self)
    }
}
