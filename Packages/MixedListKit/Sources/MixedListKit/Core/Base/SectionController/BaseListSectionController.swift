import UIKit
import IGListKit

/// 列表 SectionController 基类
/// - 职责:
///   1. 管理 Section 内的数据和 Cell
///   2. 提供布局配置（inset、spacing 等）
///   3. 处理 Header/Footer/_SEPARATOR
///   4. 响应显示/隐藏/滚动/预加载事件
/// - 子类: 业务层 SectionController
@MainActor
open class BaseListSectionController: IGListKit.ListSectionController {

    // MARK: - Data

    /// 关联的 SectionViewModel
    public private(set) var viewModel: BaseListSectionViewModel?

    /// Section 内的模型数据数组
    public private(set) var modelsArray: [AnyObject] = []

    // MARK: - Delegates

    /// Section 显示状态代理
    public weak var sectionDelegate: ListSectionControllerDelegate?

    /// 预加载范围代理
    public weak var sectionWorkingRangeDelegate: ListSectionControllerWorkingRangeDelegate?

    /// 滚动事件代理
    public weak var sectionScrollDelegate: ListSectionControllerScrollDelegate?

    // MARK: - Configuration

    /// 容器配置
    public weak var containerConfig: ListContainerConfig?

    // MARK: - Layout State

    /// 是否是最后一个 Section
    private var _isLastSection: Bool = false

    /// 布局更新权限检查闭包
    var canUpdateLayout: (() -> Bool)?

    var isLast: Bool {
        get { _isLastSection }
        set { _isLastSection = newValue }
    }

    // MARK: - Internal State

    /// 更新状态
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

    /// 返回默认 Cell 类型（所有 item 使用相同 Cell 时重写）
    open func cellClass() -> AnyClass? { nil }

    /// 根据模型返回 Cell 类型（不同 item 使用不同 Cell 时重写）
    open func cellClass(forModel model: AnyObject, index: Int) -> AnyClass? { nil }

    /// 返回指定索引 item 的尺寸
    open func sizeForItem(atIndex index: Int, model: AnyObject, collectionViewSize: CGSize) -> CGSize { .zero }

    /// 配置 Cell
    open func configCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}

    /// SectionViewModel 绑定完成回调
    open func didBindSectionViewModel() {}

    /// item 点击事件
    open func didSelectItem(atIndex index: Int, model: AnyObject) {}

    // MARK: - Header Override

    /// 返回 Header 类型
    open func headerViewClass() -> AnyClass? { nil }

    /// 返回 Header 尺寸
    open func sizeForHeader(collectionViewSize: CGSize) -> CGSize { .zero }

    /// 配置 Header
    open func configHeaderView(_ headerView: UICollectionReusableView) {}

    // MARK: - Footer Override

    /// 返回 Footer 类型（默认根据分隔线配置返回 BaseListSeparatorView）
    open func footerViewClass() -> AnyClass? {
        showSeparator() ? BaseListSeparatorView.self : nil
    }

    /// 返回 Footer 尺寸
    open func sizeForFooter(collectionViewSize: CGSize) -> CGSize {
        showSeparator() ? CGSize(width: collectionViewSize.width, height: separatorHeight()) : .zero
    }

    /// 配置 Footer
    open func configFooterView(_ footerView: UICollectionReusableView) {
        if let separator = footerView as? BaseListSeparatorView {
            separator.separatorInsets = separatorInsets()
            separator.separatorColor = separatorColor()
        }
    }

    // MARK: - Display Override

    /// Cell 即将显示
    open func sectionWillDisplayCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}

    /// Cell 已移出屏幕
    open func sectionDidEndDisplayingCell(_ cell: UICollectionViewCell, index: Int, model: AnyObject) {}

    // MARK: - Background Override

    /// Section 背景色
    open func sectionBackgroundColor() -> UIColor? { nil }

    /// Section 背景视图布局完成回调
    open func sectionBackgroundViewDidLayout(_ view: UIView) {}

    // MARK: - Separator Override

    /// 是否显示分隔线
    open func showSeparator() -> Bool {
        guard let config = containerConfig?.separatorConfig else { return !_isLastSection }
        switch config.displayState {
        case .hideAll: return false
        case .hideLastOnly: return !_isLastSection
        case .showAll: return true
        }
    }

    /// 分隔线高度
    open func separatorHeight() -> CGFloat {
        containerConfig?.separatorConfig.height ?? 0.5
    }

    /// 分隔线边距
    open func separatorInsets() -> ListSeparatorInsets {
        containerConfig?.separatorConfig.separatorInsets ?? ListSeparatorInsets()
    }

    /// 分隔线颜色
    open func separatorColor() -> UIColor {
        containerConfig?.separatorConfig.separatorColor ?? UIColor(white: 1, alpha: 0.1)
    }

    /// Diff 比较策略
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

    /// 重新加载 Section（完全刷新）
    public func reloadAnimated(_ animated: Bool, completion: ((Bool) -> Void)?) {
        performUpdate(animated: animated) { [weak self] batchContext in
            guard let self = self else { return }
            self.updateModelsArray()
            batchContext.reload(self)
        } completion: { finished in
            completion?(finished)
        }
    }

    /// 增量更新 Section（Diff 后更新）
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

    /// 更新 Section 布局
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

    /// 获取指定索引的 Cell
    public func cell(atIndex index: Int) -> UICollectionViewCell? {
        collectionContext?.cellForItem(at: index, sectionController: self)
    }

    /// 获取所有可见的 Cell
    public func visibleCells() -> [UICollectionViewCell] {
        collectionContext?.visibleCells(for: self) ?? []
    }

    /// 获取指定索引的模型
    public func model(atIndex index: Int) -> AnyObject? {
        guard index < modelsArray.count else { return nil }
        return modelsArray[index]
    }

    // MARK: - Private

    /// 从 ViewModel 更新模型数组
    func updateModelsArray() {
        modelsArray = BaseListSectionViewModel.removeDuplicates(viewModel?.modelsArray ?? [])
    }

    /// 执行批量更新
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
