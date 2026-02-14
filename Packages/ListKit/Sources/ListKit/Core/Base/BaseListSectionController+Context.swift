import UIKit

// MARK: - ListSectionContext

extension BaseListSectionController: ListSectionContext {

    public func reloadSection(animated: Bool, completion: ((Bool) -> Void)?) {
        reloadAnimated(animated, completion: completion)
    }

    public func updateSection(animated: Bool, completion: ((Bool) -> Void)?) {
        updateAnimated(animated, completion: completion)
    }

    public func scrollToItem(atIndex index: Int, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        guard index < modelsArray.count else { return }
        collectionContext?.scroll(to: self, at: index, scrollPosition: scrollPosition, animated: animated)
    }
}
