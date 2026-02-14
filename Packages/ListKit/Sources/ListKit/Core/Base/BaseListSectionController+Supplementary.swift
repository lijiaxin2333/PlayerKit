import UIKit
import IGListKit

// MARK: - IGListSupplementaryViewSource

extension BaseListSectionController: IGListKit.ListSupplementaryViewSource {

    public func supportedElementKinds() -> [String] {
        var kinds = [String]()
        if headerViewClass() != nil { kinds.append(UICollectionView.elementKindSectionHeader) }
        if footerViewClass() != nil { kinds.append(UICollectionView.elementKindSectionFooter) }
        return kinds
    }

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
