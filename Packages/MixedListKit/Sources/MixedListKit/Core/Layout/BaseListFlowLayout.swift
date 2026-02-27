import UIKit

// MARK: - BaseListFlowLayoutDelegate

/// Flow Layout 代理协议
/// - 职责: 提供 Section 背景色、Header 吸顶配置等
@MainActor
public protocol BaseListFlowLayoutDelegate: AnyObject {

    /// 返回指定 Section 的背景色
    func backgroundColorAtSectionIndex(_ sectionIndex: Int) -> UIColor?

    /// 返回指定 Section 的 Header 是否吸顶
    func shouldStickHeaderAtSectionIndex(_ sectionIndex: Int) -> Bool

    /// Section 背景视图布局完成回调
    func sectionBackgroundViewDidLayout(_ view: UIView, atSectionIndex sectionIndex: Int)
}

public extension BaseListFlowLayoutDelegate {
    func backgroundColorAtSectionIndex(_ sectionIndex: Int) -> UIColor? { nil }
    func shouldStickHeaderAtSectionIndex(_ sectionIndex: Int) -> Bool { false }
    func sectionBackgroundViewDidLayout(_ view: UIView, atSectionIndex sectionIndex: Int) {}
}

// MARK: - BaseListFlowLayoutUserInfo

/// Layout 布局信息
/// 用于在布局刷新时指定滚动目标
@MainActor
public final class BaseListFlowLayoutUserInfo {

    /// 目标 IndexPath（用于滚动到指定 item）
    public let indexPathToAutoScroll: IndexPath?

    /// 左上角偏移
    public let leftTopOffset: CGPoint?

    /// 目标 contentOffset（用于滚动到指定位置）
    public let contentOffset: CGPoint?

    /// 创建滚动到指定 item 的信息
    public static func info(targetIndexPath: IndexPath, leftTopOffset: CGPoint) -> BaseListFlowLayoutUserInfo {
        BaseListFlowLayoutUserInfo(indexPath: targetIndexPath, leftTopOffset: leftTopOffset)
    }

    /// 创建滚动到指定位置的信息
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

// MARK: - BaseListFlowLayout

/// 列表 Flow Layout 基类
/// - 职责:
///   1. 提供 Section 背景视图
///   2. 支持 Header 吸顶
///   3. 支持布局刷新时自动滚动
@MainActor
public class BaseListFlowLayout: UICollectionViewFlowLayout {

    /// 代理
    public weak var baseDelegate: BaseListFlowLayoutDelegate?

    /// 布局刷新时的滚动信息
    public var userInfoForInvalidation: BaseListFlowLayoutUserInfo?

    /// 是否禁用装饰视图（Section 背景）
    public var disableDecorationView: Bool = false

    /// 装饰视图类型标识
    private static let decorationKind = "ListKit.SectionBackground"

    /// 装饰视图属性数组
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

        // 添加装饰视图属性
        if !disableDecorationView {
            for deco in decorationAttributes where rect.intersects(deco.frame) {
                attributes.append(deco)
            }
        }

        // 处理吸顶 Header
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

    /// 判断指定 Section 的 Header 是否吸顶
    private func shouldStickHeader(_ section: Int) -> Bool {
        baseDelegate?.shouldStickHeaderAtSectionIndex(section) ?? false
    }

    /// 准备装饰视图属性
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

    /// 如果需要，滚动到指定 Section
    private func scrollToSpecifySectionIfNeeded() {
        guard let target = targetContentOffsetForInvalidation() else { return }
        collectionView?.contentOffset = target
    }

    /// 计算布局刷新时的目标 contentOffset
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

/// 自定义布局属性
/// 用于存储 Section 背景色等额外信息
@MainActor
final class BaseListLayoutAttributes: UICollectionViewLayoutAttributes {

    /// Section 背景色
    var sectionBackgroundColor: UIColor?

    /// Section 背景视图布局完成回调
    var sectionBackgroundViewDidLayout: ((IndexPath, UIView) -> Void)?
}

// MARK: - Background View

/// Section 背景视图
@MainActor
final class BaseListSectionBackgroundView: UICollectionReusableView {

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        guard let attrs = layoutAttributes as? BaseListLayoutAttributes else { return }
        backgroundColor = attrs.sectionBackgroundColor
        attrs.sectionBackgroundViewDidLayout?(attrs.indexPath, self)
    }
}
