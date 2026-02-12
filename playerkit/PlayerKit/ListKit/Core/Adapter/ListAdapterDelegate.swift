import UIKit
import IGListKit

@MainActor
public final class ListKitAdapterDelegate: NSObject, IGListKit.ListAdapterDelegate {

    public weak var delegate: ListDisplayDelegate?

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay object: Any, at index: Int) {
        guard let vm = object as? BaseListSectionViewModel else { return }
        delegate?.listWillDisplaySectionViewModel(vm, atIndex: index)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying object: Any, at index: Int) {
        guard let vm = object as? BaseListSectionViewModel else { return }
        delegate?.listDidEndDisplayingSectionViewModel(vm, atIndex: index)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay object: Any, cell: UICollectionViewCell, at indexPath: IndexPath) {
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying object: Any, cell: UICollectionViewCell, at indexPath: IndexPath) {
    }
}
