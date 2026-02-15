import UIKit
import IGListKit

/// IGListKit 显示事件桥接器
/// - 职责:
///   1. 实现 IGListKit.ListAdapterDelegate 协议
///   2. 将 Section 显隐事件转发给 ListDisplayDelegate
@MainActor
public final class ListKitAdapterDelegate: NSObject, IGListKit.ListAdapterDelegate {

    /// 外部代理（BaseListViewController）
    public weak var delegate: ListDisplayDelegate?

    /// Section 即将显示
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay object: Any, at index: Int) {
        guard let vm = object as? BaseListSectionViewModel else { return }
        delegate?.listWillDisplaySectionViewModel(vm, atIndex: index)
    }

    /// Section 已移出屏幕
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying object: Any, at index: Int) {
        guard let vm = object as? BaseListSectionViewModel else { return }
        delegate?.listDidEndDisplayingSectionViewModel(vm, atIndex: index)
    }

    /// Cell 即将显示（暂未使用）
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay object: Any, cell: UICollectionViewCell, at indexPath: IndexPath) {
    }

    /// Cell 已移出屏幕（暂未使用）
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying object: Any, cell: UICollectionViewCell, at indexPath: IndexPath) {
    }
}
