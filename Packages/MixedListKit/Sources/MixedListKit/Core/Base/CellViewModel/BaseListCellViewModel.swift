import UIKit

/// 列表 CellViewModel 基类
/// - 职责:
///   1. 持有 Cell 数据
///   2. 提供 Cell 类型和尺寸
///   3. 管理 Cell 尺寸缓存
///   4. 提供 Section 操作能力
/// - 子类: 业务层 CellViewModel
@MainActor
open class BaseListCellViewModel<ModelType>: NSObject, ListCellViewModelProtocol {

    // MARK: - Data

    /// Cell 数据
    public let cellData: ModelType?

    /// 列表上下文
    public private(set) weak var listContext: ListContext?

    /// 所属的 SectionViewModel
    private weak var _sectionViewModel: BaseListSectionViewModel?

    // MARK: - Size Cache

    /// 缓存的 Cell 尺寸
    private var _cachedCellSize: CGSize?

    /// 是否可见
    public var isVisible: Bool = false

    // MARK: - Init

    /// 初始化 CellViewModel
    /// - Parameters:
    ///   - cellData: Cell 数据
    ///   - listContext: 列表上下文
    ///   - sectionViewModel: 所属的 SectionViewModel（可传 nil，后续通过 updateSectionViewModel 绑定）
    public init(cellData: ModelType?, listContext: ListContext?, sectionViewModel: BaseListSectionViewModel?) {
        self.cellData = cellData
        self.listContext = listContext
        self._sectionViewModel = sectionViewModel
        super.init()
    }

    @available(*, unavailable)
    public override init() {
        fatalError()
    }

    // MARK: - Cell Configuration

    /// 是否启用 Cell 尺寸缓存
    open var cacheCellSizeEnabled: Bool {
        listContext?.cellSizeCached() ?? false
    }

    /// 返回 Cell 类型
    open func cellClass() -> AnyClass {
        UICollectionViewCell.self
    }

    /// 返回 Cell 尺寸（支持缓存）
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

    /// 计算并返回 Cell 期望尺寸（子类重写）
    open func preferredCellSize() -> CGSize {
        .zero
    }

    /// 清除缓存的 Cell 尺寸
    public func clearCellSizeCache() {
        _cachedCellSize = nil
    }

    // MARK: - Section Access

    /// 获取当前 SectionViewModel
    public func obtainCurrentSectionViewModel() -> BaseListSectionViewModel {
        guard let vm = _sectionViewModel else {
            fatalError("SectionViewModel has been released")
        }
        return vm
    }

    /// 更新 SectionViewModel
    public func updateSectionViewModel(_ sectionViewModel: BaseListSectionViewModel) {
        _sectionViewModel = sectionViewModel
    }

    // MARK: - List Operations

    /// 重新加载可见 Section
    public func reloadVisibleSection() {
        _sectionViewModel?.sectionContext?.reloadSection(animated: false, completion: nil)
    }

    /// 重新加载当前 Section
    public func reloadCurrentSection() {
        _sectionViewModel?.sectionContext?.reloadSection(animated: false, completion: nil)
    }

    /// 增量更新当前 Section
    public func updateCurrentSection() {
        _sectionViewModel?.sectionContext?.updateSection(animated: false, completion: nil)
    }

    /// 移除当前 Section
    public func removeCurrentSectionWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let sectionVM = _sectionViewModel,
              let listVM = listContext?.listViewModel() else { return }
        listVM.removeSectionViewModels([sectionVM], animated: animated, completion: completion)
    }

    /// 移除当前 Cell
    public func removeCurrentCellWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let sectionVM = _sectionViewModel else { return }
        sectionVM.removeModels([self], animated: animated, completion: completion)
    }
}
