import UIKit

// MARK: - ListSectionContext

/// Section 上下文协议实现
/// 提供 Section 级别的操作能力
extension BaseListSectionController: ListSectionContext {

    /// 重新加载 Section
    public func reloadSection(animated: Bool, completion: ((Bool) -> Void)?) {
        reloadAnimated(animated, completion: completion)
    }

    /// 增量更新 Section
    public func updateSection(animated: Bool, completion: ((Bool) -> Void)?) {
        updateAnimated(animated, completion: completion)
    }

    /// 滚动到指定 item
    public func scrollToItem(atIndex index: Int, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        guard index < modelsArray.count else { return }
        collectionContext?.scroll(to: self, at: index, scrollPosition: scrollPosition, animated: animated)
    }
}
