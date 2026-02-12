import UIKit

@MainActor
open class BaseListCellViewModel<ModelType>: NSObject, ListCellViewModelProtocol {

    public let cellData: ModelType?
    public private(set) weak var listContext: ListContext?
    private weak var _sectionViewModel: BaseListSectionViewModel?

    private var _cachedCellSize: CGSize?

    public var isVisible: Bool = false

    public init(cellData: ModelType?, listContext: ListContext?, sectionViewModel: BaseListSectionViewModel) {
        self.cellData = cellData
        self.listContext = listContext
        self._sectionViewModel = sectionViewModel
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError()
    }

    open var cacheCellSizeEnabled: Bool {
        listContext?.cellSizeCached() ?? false
    }

    open func cellClass() -> AnyClass {
        UICollectionViewCell.self
    }

    open func cellSize() -> CGSize {
        if cacheCellSizeEnabled, let cached = _cachedCellSize {
            return cached
        }
        let size = preferredCellSize()
        if cacheCellSizeEnabled {
            _cachedCellSize = size
        }
        return size
    }

    open func preferredCellSize() -> CGSize {
        .zero
    }

    public func clearCellSizeCache() {
        _cachedCellSize = nil
    }

    public func obtainCurrentSectionViewModel() -> BaseListSectionViewModel {
        guard let vm = _sectionViewModel else {
            fatalError("SectionViewModel has been released")
        }
        return vm
    }

    public func updateSectionViewModel(_ sectionViewModel: BaseListSectionViewModel) {
        _sectionViewModel = sectionViewModel
    }

    // MARK: - List Operations

    public func reloadVisibleSection() {
        _sectionViewModel?.sectionContext?.reloadSection(animated: false, completion: nil)
    }

    public func reloadCurrentSection() {
        _sectionViewModel?.sectionContext?.reloadSection(animated: false, completion: nil)
    }

    public func updateCurrentSection() {
        _sectionViewModel?.sectionContext?.updateSection(animated: false, completion: nil)
    }

    public func removeCurrentSectionWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let sectionVM = _sectionViewModel,
              let listVM = listContext?.listViewModel() else { return }
        listVM.removeSectionViewModels([sectionVM], animated: animated, completion: completion)
    }

    public func removeCurrentCellWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let sectionVM = _sectionViewModel else { return }
        sectionVM.removeModels([self], animated: animated, completion: completion)
    }
}
