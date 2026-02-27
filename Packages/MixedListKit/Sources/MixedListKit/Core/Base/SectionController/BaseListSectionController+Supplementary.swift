import UIKit
import IGListKit

// MARK: - IGListSupplementaryViewSource

/// IGListKit 补充视图数据源实现
/// 提供 Header/Footer 的创建和配置
extension BaseListSectionController: IGListKit.ListSupplementaryViewSource {

    /// 返回支持的补充视图类型
    public func supportedElementKinds() -> [String] {
        var kinds = [String]()
        if headerViewClass() != nil { kinds.append(UICollectionView.elementKindSectionHeader) }
        if footerViewClass() != nil { kinds.append(UICollectionView.elementKindSectionFooter) }
        return kinds
    }

    /// 创建补充视图
    public func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        if elementKind == UICollectionView.elementKindSectionHeader, let cls = headerViewClass() {
            let view = collectionContext!.dequeueReusableSupplementaryView(ofKind: elementKind, for: self, class: cls, at: index)
            configHeaderView(view)
            return view
        }
        if elementKind == UICollectionView.elementKindSectionFooter, let cls = footerViewClass() {
            let view = collectionContext!.dequeueReusableSupplementaryView(ofKind: elementKind, for: self, class: cls, at: index)
            configFooterView(view)
            return view
        }
        return UICollectionReusableView()
    }

    /// 返回补充视图尺寸
    public func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        let containerSize = collectionContext!.containerSize
        if elementKind == UICollectionView.elementKindSectionHeader {
            return sizeForHeader(collectionViewSize: containerSize)
        }
        if elementKind == UICollectionView.elementKindSectionFooter {
            return sizeForFooter(collectionViewSize: containerSize)
        }
        return .zero
    }
}
