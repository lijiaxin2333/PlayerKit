import IGListKit

// MARK: - IGListScrollDelegate

/// IGListKit 滚动事件代理实现
/// 将 Section 内的滚动事件转发给代理
extension BaseListSectionController: IGListKit.ListScrollDelegate {

    /// Section 滚动中
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didScroll sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidScroll(self)
    }

    /// Section 开始拖拽
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willBeginDragging sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerWillBeginDragging(self)
    }

    /// Section 结束拖拽
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDragging sectionController: IGListKit.ListSectionController, willDecelerate decelerate: Bool) {
        sectionScrollDelegate?.sectionControllerDidEndDragging(self, willDecelerate: decelerate)
    }

    /// Section 减速结束
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDeceleratingSectionController sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidEndDecelerating(self)
    }
}
