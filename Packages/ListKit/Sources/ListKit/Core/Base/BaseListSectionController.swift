import UIKit
import IGListKit

@MainActor
open class BaseListSectionController: IGListKit.ListSectionController {

    // MARK: - Data

    public private(set) var viewModel: BaseListSectionViewModel?
    public private(set) var modelsArray: [AnyObject] = []

    // MARK: - Delegates

    public weak var sectionDelegate: ListSectionControllerDelegate?
    public weak var sectionWorkingRangeDelegate: ListSectionControllerWorkingRangeDelegate?
    public weak var sectionScrollDelegate: ListSectionControllerScrollDelegate?

    // MARK: - Configuration

    public weak var containerConfig: ListContainerConfig?

    // MARK: - Layout State

    private var _isLastSection: Bool = false
    var canUpdateLayout: (() -> Bool)?

    var isLast: Bool {
        get { _isLastSection }
        set { _isLastSection = newValue }
    }

    // MARK: - Internal State

    private enum UpdateState {
        case idle, queued, applied
    }
    private var state: UpdateState = .idle

    // MARK: - Init

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
            MainActor.assumeIsolated {
                self?.state = .idle
            }
            completion?(finished)
        })
    }
}
