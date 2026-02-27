import UIKit
import IGListKit

/// IGListKit 更新事件桥接器
/// - 职责:
///   1. 实现 IGListKit.ListAdapterUpdaterDelegate 协议
///   2. 监听列表数据更新事件（reloadData、performBatchUpdates 等）
///   3. 将更新事件转发给 ListUpdateDelegate
@MainActor
public final class ListKitAdapterUpdaterDelegate:
    NSObject,
    IGListKit.ListAdapterUpdaterDelegate {

    /// 外部更新代理
    public weak var updateDelegate: ListUpdateDelegate?

    /// 关联的 ViewController
    private weak var viewController: UIViewController?

    public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    // MARK: - Diff 相关

    /// 即将开始 Diff 计算
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willDiffFromObjects fromObjects: [any IGListKit.ListDiffable]?, toObjects: [any IGListKit.ListDiffable]?) {
    }

    /// Diff 计算完成
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didDiffWithResults listIndexSetResults: IGListKit.ListIndexSetResult?, onBackgroundThread: Bool) {
    }

    // MARK: - 批量更新

    /// 即将执行批量更新
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willPerformBatchUpdatesWith collectionView: UICollectionView, fromObjects: [any IGListKit.ListDiffable]?, toObjects: [any IGListKit.ListDiffable]?, listIndexSetResult: IGListKit.ListIndexSetResult?, animated: Bool) {
    }

    /// 批量更新完成
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didPerformBatchUpdates updates: IGListKit.ListBatchUpdateData, collectionView: UICollectionView) {
        updateDelegate?.listDidPerformBatchUpdates(collectionView: collectionView)
    }

    // MARK: - 单项操作

    /// 即将插入 Cell
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willInsert indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    /// 即将删除 Cell
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willDelete indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    /// 即将移动 Cell
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willMoveFrom fromIndexPath: IndexPath, to toIndexPath: IndexPath, collectionView: UICollectionView) {
    }

    /// 即将重载 Cell
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReload indexPaths: [IndexPath], collectionView: UICollectionView) {
    }

    /// 即将重载 Section
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReloadSections sections: IndexSet, collectionView: UICollectionView) {
    }

    // MARK: - reloadData

    /// 即将 reloadData
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willReloadDataWith collectionView: UICollectionView, isFallbackReload: Bool) {
        updateDelegate?.listWillReloadData(collectionView: collectionView)
    }

    /// reloadData 完成
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didReloadDataWith collectionView: UICollectionView, isFallbackReload: Bool) {
        updateDelegate?.listDidReloadData(collectionView: collectionView)
    }

    // MARK: - 错误处理

    /// 即将崩溃（IGListKit 检测到严重错误）
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, collectionView: UICollectionView, willCrashWith exception: NSException, from fromObjects: [Any]?, to toObjects: [Any]?, diffResult: IGListKit.ListIndexSetResult, updates: IGListKit.ListBatchUpdateData) {
    }

    /// 即将崩溃（CollectionView 相关错误）
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, willCrashWithCollectionView collectionView: Any?, sectionControllerClass: AnyClass?) {
    }

    /// 更新完成但无变化
    public func listAdapterUpdater(_ listAdapterUpdater: IGListKit.ListAdapterUpdater, didFinishWithoutUpdatesWith collectionView: UICollectionView?) {
    }
}
