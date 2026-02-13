import UIKit

@MainActor
public protocol BaseListFlowLayoutDelegate: AnyObject {
    func backgroundColorAtSectionIndex(_ sectionIndex: Int) -> UIColor?
    func shouldStickHeaderAtSectionIndex(_ sectionIndex: Int) -> Bool
    func sectionBackgroundViewDidLayout(_ view: UIView, atSectionIndex sectionIndex: Int)
}

public extension BaseListFlowLayoutDelegate {
    func backgroundColorAtSectionIndex(_ sectionIndex: Int) -> UIColor? { nil }
    func shouldStickHeaderAtSectionIndex(_ sectionIndex: Int) -> Bool { false }
    func sectionBackgroundViewDidLayout(_ view: UIView, atSectionIndex sectionIndex: Int) {}
}

@MainActor
public final class BaseListFlowLayoutUserInfo {
    public let indexPathToAutoScroll: IndexPath?
    public let leftTopOffset: CGPoint?
    public let contentOffset: CGPoint?

    public static func info(targetIndexPath: IndexPath, leftTopOffset: CGPoint) -> BaseListFlowLayoutUserInfo {
        BaseListFlowLayoutUserInfo(indexPath: targetIndexPath, leftTopOffset: leftTopOffset)
    }

    public static func info(targetContentOffset: CGPoint) -> BaseListFlowLayoutUserInfo {
        BaseListFlowLayoutUserInfo(contentOffset: targetContentOffset)
    }

    private init(indexPath: IndexPath, leftTopOffset: CGPoint) {
        self.indexPathToAutoScroll = indexPath
        self.leftTopOffset = leftTopOffset
        self.contentOffset = nil
    }

    private init(contentOffset: CGPoint) {
        self.indexPathToAutoScroll = nil
        self.leftTopOffset = nil
        self.contentOffset = contentOffset
    }
}

@MainActor
public class BaseListFlowLayout: UICollectionViewFlowLayout {

    public weak var baseDelegate: BaseListFlowLayoutDelegate?
    public var userInfoForInvalidation: BaseListFlowLayoutUserInfo?
    public var disableDecorationView: Bool = false

    private static let decorationKind = "ListKit.SectionBackground"
    private var decorationAttributes: [BaseListLayoutAttributes] = []

    public override init() {
        super.init()
        register(BaseListSectionBackgroundView.self, forDecorationViewOfKind: Self.decorationKind)
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func prepare() {
        super.prepare()
        prepareDecorationAttributes()
        scrollToSpecifySectionIfNeeded()
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard var attributes = super.layoutAttributesForElements(in: rect)?.map({ $0.copy() as! UICollectionViewLayoutAttributes }) else { return nil }

        if !disableDecorationView {
            for deco in decorationAttributes where rect.intersects(deco.frame) {
                attributes.append(deco)
            }
        }

        var missingSections = IndexSet()
        for attr in attributes {
            let section = attr.indexPath.section
            guard shouldStickHeader(section) else { continue }
            if attr.representedElementCategory == .cell {
                missingSections.insert(section)
            }
            if attr.representedElementKind == UICollectionView.elementKindSectionHeader {
                missingSections.insert(section)
            }
        }
        attributes.removeAll { attr in
            attr.representedElementKind == UICollectionView.elementKindSectionHeader && shouldStickHeader(attr.indexPath.section)
        }

        for section in missingSections {
            if let stickyHeader = layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: section)) {
                attributes.append(stickyHeader)
            }
        }

        return attributes
    }

    public override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attrs = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }

        guard elementKind == UICollectionView.elementKindSectionHeader, shouldStickHeader(indexPath.section) else {
            return attrs
        }

        guard let collectionView = collectionView else { return attrs }
        let contentOffset = collectionView.contentOffset
        var nextHeaderOrigin = CGPoint(x: CGFloat.infinity, y: CGFloat.infinity)
        let numberOfSections = collectionView.numberOfSections
        if indexPath.section + 1 < numberOfSections {
            if let nextAttrs = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: IndexPath(item: 0, section: indexPath.section + 1)) {
                nextHeaderOrigin = nextAttrs.frame.origin
            }
        }

        var frame = attrs.frame
        if scrollDirection == .vertical {
            frame.origin.y = min(max(contentOffset.y, frame.origin.y), nextHeaderOrigin.y - frame.height)
        } else {
            frame.origin.x = min(max(contentOffset.x, frame.origin.x), nextHeaderOrigin.x - frame.width)
        }
        attrs.zIndex = 1024
        attrs.frame = frame
        return attrs
    }

    public override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if elementKind == Self.decorationKind {
            return decorationAttributes.first { $0.indexPath.section == indexPath.section }
        }
        return super.layoutAttributesForDecorationView(ofKind: elementKind, at: indexPath)
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { true }

    public override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        if let target = targetContentOffsetForInvalidation() {
            return target
        }
        return proposedContentOffset
    }

    // MARK: - Private

    private func shouldStickHeader(_ section: Int) -> Bool {
        baseDelegate?.shouldStickHeaderAtSectionIndex(section) ?? false
    }

    private func prepareDecorationAttributes() {
        guard !disableDecorationView, let collectionView = collectionView else { return }
        decorationAttributes.removeAll()

        let numberOfSections = collectionView.numberOfSections
        for section in 0..<numberOfSections {
            let numberOfItems = collectionView.numberOfItems(inSection: section)
            guard numberOfItems > 0 else { continue }

            let firstIP = IndexPath(item: 0, section: section)
            let lastIP = IndexPath(item: numberOfItems - 1, section: section)
            guard let firstAttrs = layoutAttributesForItem(at: firstIP),
                  let lastAttrs = layoutAttributesForItem(at: lastIP) else { continue }

            guard let delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout else { continue }
            let sectionInset = delegate.collectionView?(collectionView, layout: self, insetForSectionAt: section) ?? .zero

            var sectionFrame = firstAttrs.frame.union(lastAttrs.frame)
            sectionFrame.origin.x -= sectionInset.left
            sectionFrame.origin.y -= sectionInset.top
            if scrollDirection == .horizontal {
                sectionFrame.size.width += sectionInset.left + sectionInset.right
                sectionFrame.size.height = collectionView.frame.height
            } else {
                sectionFrame.size.width = collectionView.frame.width
                sectionFrame.size.height += sectionInset.top + sectionInset.bottom
            }

            let attrs = BaseListLayoutAttributes(forDecorationViewOfKind: Self.decorationKind, with: IndexPath(item: 0, section: section))
            attrs.frame = sectionFrame
            attrs.zIndex = -1
            attrs.sectionBackgroundColor = baseDelegate?.backgroundColorAtSectionIndex(section)
            attrs.sectionBackgroundViewDidLayout = { [weak self] indexPath, view in
                self?.baseDelegate?.sectionBackgroundViewDidLayout(view, atSectionIndex: indexPath.section)
            }
            decorationAttributes.append(attrs)
        }
    }

    private func scrollToSpecifySectionIfNeeded() {
        guard let target = targetContentOffsetForInvalidation() else { return }
        collectionView?.contentOffset = target
    }

    private func targetContentOffsetForInvalidation() -> CGPoint? {
        guard let info = userInfoForInvalidation else { return nil }
        if let offset = info.contentOffset {
            return offset
        }
        if let indexPath = info.indexPathToAutoScroll, let collectionView = collectionView {
            guard indexPath.section < collectionView.numberOfSections,
                  indexPath.item < collectionView.numberOfItems(inSection: indexPath.section) else { return nil }
            if let itemAttrs = layoutAttributesForItem(at: indexPath) {
                let leftTop = info.leftTopOffset ?? .zero
                return CGPoint(x: itemAttrs.frame.origin.x + leftTop.x, y: itemAttrs.frame.origin.y + leftTop.y)
            }
        }
        return nil
    }
}

// MARK: - Layout Attributes

@MainActor
final class BaseListLayoutAttributes: UICollectionViewLayoutAttributes {
    var sectionBackgroundColor: UIColor?
    var sectionBackgroundViewDidLayout: ((IndexPath, UIView) -> Void)?
}

// MARK: - Background View

@MainActor
final class BaseListSectionBackgroundView: UICollectionReusableView {
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attrs = layoutAttributes as? BaseListLayoutAttributes else { return }
        backgroundColor = attrs.sectionBackgroundColor
        attrs.sectionBackgroundViewDidLayout?(attrs.indexPath, self)
    }
}
