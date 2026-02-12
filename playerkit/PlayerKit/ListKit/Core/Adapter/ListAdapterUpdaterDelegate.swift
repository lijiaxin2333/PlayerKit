import UIKit
import IGListKit

@MainActor
public final class ListKitAdapterUpdaterDelegate: NSObject, IGListKit.ListAdapterUpdaterDelegate {

    public weak var updateDelegate: ListUpdateDelegate?
    private weak var viewController: UIViewController?

    public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willDiffFromObjects fromObjects: [any IGListKit.ListDiffable]?, toObjects: [any IGListKit.ListDiffable]?) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didDiffWithResults listIndexSetResults: IGListKit.ListIndexSetResult?, onBackgroundThread: Bool) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willPerformBatchUpdatesWith collectionView: UICollectionView, fromObjects: [any IGListKit.ListDiffable]?, toObjects: [any IGListKit.ListDiffable]?, listIndexSetResult: IGListKit.ListIndexSetResult?, animated: Bool) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didPerformBatchUpdates updates: IGListKit.ListBatchUpdateData, collectionView: UICollectionView) {
        updateDelegate?.listDidPerformBatchUpdates(collectionView: collectionView)
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willInsert indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willDelete indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willMoveFrom fromIndexPath: IndexPath, to toIndexPath: IndexPath, collectionView: UICollectionView) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReload indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReloadSections sections: IndexSet, collectionView: UICollectionView) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReloadDataWith collectionView: UICollectionView, isFallbackReload: Bool) {
        updateDelegate?.listWillReloadData(collectionView: collectionView)
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didReloadDataWith collectionView: UICollectionView, isFallbackReload: Bool) {
        updateDelegate?.listDidReloadData(collectionView: collectionView)
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, collectionView: UICollectionView, willCrashWith exception: NSException, from fromObjects: [Any]?, to toObjects: [Any]?, diffResult: IGListKit.ListIndexSetResult, updates: IGListKit.ListBatchUpdateData) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willCrashWithCollectionView collectionView: Any?, sectionControllerClass: AnyClass?) {
    }

    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didFinishWithoutUpdatesWith collectionView: UICollectionView?) {
    }
}
