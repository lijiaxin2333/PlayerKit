import UIKit
import IGListKit

@MainActor
open class BaseListSectionController: IGListKit.ListSectionController, IGListKit.ListSupplementaryViewSource, IGListKit.ListDisplayDelegate, IGListKit.ListWorkingRangeDelegate, IGListKit.ListScrollDelegate, ListSectionContext, ListControllerLifeCycle {

    public private(set) var viewModel: BaseListSectionViewModel?
    public private(set) var modelsArray: [AnyObject] = []

    public weak var sectionDelegate: ListSectionControllerDelegate?
    public weak var sectionWorkingRangeDelegate: ListSectionControllerWorkingRangeDelegate?
    public weak var sectionScrollDelegate: ListSectionControllerScrollDelegate?
    public weak var containerConfig: ListContainerConfig?

    private var _isLastSection: Bool = false
    var canUpdateLayout: (() -> Bool)?

    var isLast: Bool {
        get { _isLastSection }
        set { _isLastSection = newValue }
    }

    private enum UpdateState {
        case idle, queued, applied
    }
    private var state: UpdateState = .idle

    public required override init() {
        super.init()
        self.supplementaryViewSource = self
        self.displayDelegate = self
        self.workingRangeDelegate = self
        self.scrollDelegate = self
    }

    // MARK: - Override Points

    open func cellClass() -> AnyClass? { nil }
    open func cellClass(forModel model: AnyObject, index: Int) -> AnyClass? { nil }
    open func sizeForItem(atIndex index: Int, model: AnyObject, collectionViewSize: CGSize) -> CGSize { .zero }
    open func configCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}
    open func didBindSectionViewModel() {}
    open func didSelectItem(atIndex index: Int, model: AnyObject) {}

    // MARK: - Header Override

    open func headerViewClass() -> AnyClass? { nil }
    open func sizeForHeader(collectionViewSize: CGSize) -> CGSize { .zero }
    open func configHeaderView(_ headerView: UICollectionReusableView) {}

    // MARK: - Footer Override

    open func footerViewClass() -> AnyClass? {
        showSeparator() ? BaseListSeparatorView.self : nil
    }

    open func sizeForFooter(collectionViewSize: CGSize) -> CGSize {
        showSeparator() ? CGSize(width: collectionViewSize.width, height: separatorHeight()) : .zero
    }

    open func configFooterView(_ footerView: UICollectionReusableView) {
        if let separator = footerView as? BaseListSeparatorView {
            separator.separatorInsets = separatorInsets()
            separator.separatorColor = separatorColor()
        }
    }

    // MARK: - Display Override

    open func sectionWillDisplayCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}
    open func sectionDidEndDisplayingCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}

    // MARK: - Background Override

    open func sectionBackgroundColor() -> UIColor? { nil }
    open func sectionBackgroundViewDidLayout(_ view: UIView) {}

    // MARK: - Separator Override

    open func showSeparator() -> Bool {
        guard let config = containerConfig?.separatorConfig else { return !_isLastSection }
        switch config.displayState {
        case .hideAll: return false
        case .hideLastOnly: return !_isLastSection
        case .showAll: return true
        }
    }

    open func separatorHeight() -> CGFloat {
        containerConfig?.separatorConfig.height ?? 0.5
    }

    open func separatorInsets() -> ListSeparatorInsets {
        containerConfig?.separatorConfig.separatorInsets ?? ListSeparatorInsets()
    }

    open func separatorColor() -> UIColor {
        containerConfig?.separatorConfig.separatorColor ?? UIColor(white: 1, alpha: 0.1)
    }

    open func diffOption() -> ListDiffOption { .pointerPersonality }

    // MARK: - IGListSectionController Overrides

    open override func numberOfItems() -> Int {
        modelsArray.count
    }

    open override func sizeForItem(at index: Int) -> CGSize {
        guard index < modelsArray.count else { return .zero }
        return sizeForItem(atIndex: index, model: modelsArray[index], collectionViewSize: collectionContext!.containerSize)
    }

    open override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard index < modelsArray.count else { return UICollectionViewCell() }
        let model = modelsArray[index]
        let cls: AnyClass = cellClass() ?? cellClass(forModel: model, index: index) ?? UICollectionViewCell.self
        let cell = collectionContext!.dequeueReusableCell(of: cls, for: self, at: index)
        configCell(cell, index: index, model: model)
        return cell
    }

    open override func didUpdate(to object: Any) {
        guard let vm = object as? BaseListSectionViewModel else { return }
        viewModel = vm
        updateModelsArray()
        didBindSectionViewModel()
    }

    open override func didSelectItem(at index: Int) {
        guard index < modelsArray.count else { return }
        didSelectItem(atIndex: index, model: modelsArray[index])
    }

    // MARK: - IGListSupplementaryViewSource

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

    // MARK: - IGListDisplayDelegate

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerWillDisplay(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController) {
        sectionDelegate?.sectionControllerDidEndDisplaying(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willDisplay sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionWillDisplayCell(cell, index: index, model: modelsArray[index])
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDisplaying sectionController: IGListKit.ListSectionController, cell: UICollectionViewCell, at index: Int) {
        guard index < modelsArray.count else { return }
        sectionDidEndDisplayingCell(cell, index: index, model: modelsArray[index])
    }

    // MARK: - IGListWorkingRangeDelegate

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerWillEnterWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerWillEnterWorkingRange(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerDidExitWorkingRange sectionController: IGListKit.ListSectionController) {
        sectionWorkingRangeDelegate?.sectionControllerDidExitWorkingRange(self)
    }

    // MARK: - IGListScrollDelegate

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didScroll sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidScroll(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, willBeginDragging sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerWillBeginDragging(self)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDragging sectionController: IGListKit.ListSectionController, willDecelerate decelerate: Bool) {
        sectionScrollDelegate?.sectionControllerDidEndDragging(self, willDecelerate: decelerate)
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, didEndDeceleratingSectionController sectionController: IGListKit.ListSectionController) {
        sectionScrollDelegate?.sectionControllerDidEndDecelerating(self)
    }

    // MARK: - ListSectionContext

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

    // MARK: - Update

    public func reloadAnimated(_ animated: Bool, completion: ((Bool) -> Void)?) {
        performUpdate(animated: animated) { [weak self] batchContext in
            guard let self = self else { return }
            self.updateModelsArray()
            batchContext.reload(self)
        } completion: { finished in
            completion?(finished)
        }
    }

    public func updateAnimated(_ animated: Bool, completion: ((Bool) -> Void)?) {
        guard state == .idle else {
            completion?(false)
            return
        }
        performUpdate(animated: animated) { [weak self] batchContext in
            guard let self = self else { return }
            let oldModels = self.modelsArray
            self.updateModelsArray()
            let oldArray: [any IGListKit.ListDiffable] = oldModels.map { ListDiffableWrapper($0) }
            let newArray: [any IGListKit.ListDiffable] = self.modelsArray.map { ListDiffableWrapper($0) }
            let result = IGListKit.ListDiff(oldArray: oldArray, newArray: newArray, option: .equality)
            batchContext.delete(in: self, at: result.deletes)
            batchContext.insert(in: self, at: result.inserts)
            for move in result.moves {
                batchContext.move(in: self, from: move.from, to: move.to)
            }
        } completion: { finished in
            completion?(finished)
        }
    }

    public func updateLayoutAnimated(_ animated: Bool, completion: ((Bool) -> Void)?) {
        let block = { [weak self] in
            guard let self = self else { return }
            let canUpdate = self.canUpdateLayout?() ?? true
            guard canUpdate else {
                completion?(true)
                return
            }
            self.collectionContext?.invalidateLayout(for: self, completion: { finished in
                completion?(finished)
            })
        }
        if animated {
            block()
        } else {
            UIView.performWithoutAnimation(block)
        }
    }

    // MARK: - Access

    public func cell(atIndex index: Int) -> UICollectionViewCell? {
        collectionContext?.cellForItem(at: index, sectionController: self)
    }

    public func visibleCells() -> [UICollectionViewCell] {
        collectionContext?.visibleCells(for: self) ?? []
    }

    public func model(atIndex index: Int) -> AnyObject? {
        guard index < modelsArray.count else { return nil }
        return modelsArray[index]
    }

    // MARK: - Private

    func updateModelsArray() {
        modelsArray = BaseListSectionViewModel.removeDuplicates(viewModel?.modelsArray ?? [])
    }

    private func performUpdate(animated: Bool, updates: @escaping (any IGListKit.ListBatchContext) -> Void, completion: ((Bool) -> Void)?) {
        guard state == .idle else {
            completion?(false)
            return
        }
        state = .queued
        collectionContext?.performBatch(animated: animated, updates: { [weak self] batchContext in
            updates(batchContext)
            self?.state = .applied
        }, completion: { [weak self] finished in
            self?.state = .idle
            completion?(finished)
        })
    }
}

// MARK: - BaseListSeparatorView

@MainActor
public final class BaseListSeparatorView: UICollectionReusableView {

    private let lineView = UIView()

    public var separatorInsets: ListSeparatorInsets = ListSeparatorInsets() {
        didSet { setNeedsLayout() }
    }

    public var separatorColor: UIColor = UIColor(white: 1, alpha: 0.1) {
        didSet { lineView.backgroundColor = separatorColor }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        lineView.backgroundColor = separatorColor
        addSubview(lineView)
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        lineView.frame = CGRect(
            x: separatorInsets.left,
            y: 0,
            width: bounds.width - separatorInsets.left - separatorInsets.right,
            height: bounds.height
        )
    }
}

// MARK: - Private helper for removeDuplicates

fileprivate extension BaseListSectionViewModel {
    static func removeDuplicates(_ objects: [AnyObject]) -> [AnyObject] {
        var seen = Set<ObjectIdentifier>()
        return objects.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }
}

// MARK: - ListDiffableWrapper

final class ListDiffableWrapper: NSObject, IGListKit.ListDiffable {
    let wrapped: AnyObject

    init(_ object: AnyObject) {
        self.wrapped = object
    }

    func diffIdentifier() -> any NSObjectProtocol {
        return ObjectIdentifier(wrapped) as AnyObject as! NSObjectProtocol
    }

    func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        guard let other = object as? ListDiffableWrapper else { return false }
        return wrapped === other.wrapped
    }
}
