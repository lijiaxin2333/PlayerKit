import UIKit
import IGListKit

/// 列表 SectionViewModel 基类
/// - 职责:
///   1. 管理 Section 内的模型数据
///   2. 提供布局配置（inset、spacing 等）
///   3. 管理数据状态（刷新、加载更多、错误等）
///   4. 提供数据操作方法（增删改查）
/// - 子类: 业务层 SectionViewModel
@MainActor
open class BaseListSectionViewModel: NSObject,
                                     IGListKit.ListDiffable,
                                     ListSectionViewModelProtocol {

    // MARK: - Data

    /// Section 内的模型数据数组（已去重）
    public private(set) var modelsArray: [AnyObject]

    // MARK: - Layout Configuration

    /// Section 内边距
    public var inset: UIEdgeInsets = .zero

    /// 列数（0 表示单列）
    public var columnCount: Int = 0

    /// 行间距
    public var minimumLineSpacing: CGFloat = 0

    /// 列间距
    public var minimumInteritemSpacing: CGFloat = 0

    // MARK: - Data State

    /// 数据源状态
    public var dataSourceState: ListDataSourceState = .none

    /// 是否有更多数据
    public var dataSourceHasMore: Bool = false

    /// 刷新状态
    public var refreshState: ListDataLoadState = .isNotLoading

    /// 加载更多状态
    public var loadMoreState: ListDataLoadState = .isNotLoading

    /// 错误信息
    public var errorMessage: String = ""

    // MARK: - Context

    /// 列表上下文
    public private(set) weak var listContext: ListContext?

    /// 原始响应数据
    public private(set) var responseModel: Any?

    /// 是否可见
    public private(set) var isVisible: Bool = false

    /// Section 上下文（用于 Section 内操作）
    public weak var sectionContext: ListSectionContext?

    /// 容器配置
    public weak var containerConfig: ListContainerConfig?

    // MARK: - Init

    /// 使用模型数组初始化
    public init(modelsArray: [AnyObject] = []) {
        self.modelsArray = Self.removeDuplicates(modelsArray)
        super.init()
    }

    /// 使用上下文和响应数据初始化
    public init(listContext: ListContext?, responseModel: Any?) {
        self.listContext = listContext
        self.responseModel = responseModel
        self.modelsArray = []
        super.init()
    }

    /// 更新列表上下文
    public func updateListContext(_ context: ListContext?) {
        self.listContext = context
    }

    /// 更新可见性
    public func updateVisibility(_ visible: Bool) {
        self.isVisible = visible
    }

    /// 返回对应的 SectionController 类型
    /// 子类必须重写此方法返回对应的 Controller 类型
    open class func sectionControllerClass() -> BaseListSectionController.Type? {
        nil
    }

    // MARK: - Model Operations

    /// 追加模型
    public func appendModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !models.isEmpty else { return }
        let cleaned = Self.removeDuplicates(models)
        if modelsArray.isEmpty {
            modelsArray = cleaned
            sectionContext?.reloadSection(animated: animated, completion: completion)
            return
        }
        modelsArray.append(contentsOf: cleaned)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    /// 移除模型
    public func removeModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !models.isEmpty else { return }
        modelsArray.removeAll { item in models.contains(where: { $0 === item }) }
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    /// 移除所有模型
    public func removeAllModels(animated: Bool = false) {
        modelsArray = []
        sectionContext?.reloadSection(animated: animated, completion: nil)
    }

    /// 重新加载数据（完全替换）
    public func reloadByModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        modelsArray = Self.removeDuplicates(models)
        sectionContext?.reloadSection(animated: animated, completion: completion)
    }

    /// 增量更新数据（Diff 后更新）
    public func updateByModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        modelsArray = Self.removeDuplicates(models)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    /// 插入模型到指定位置
    public func insertModel(_ model: AnyObject, atIndex index: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard index <= modelsArray.count else { return }
        guard !modelsArray.contains(where: { $0 === model }) else { return }
        if index == modelsArray.count {
            appendModels([model], animated: animated, completion: completion)
            return
        }
        modelsArray.insert(model, at: index)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    /// 移动模型
    public func moveItem(fromIndex source: Int, toIndex dest: Int) {
        guard source < modelsArray.count, dest < modelsArray.count else { return }
        let item = modelsArray.remove(at: source)
        modelsArray.insert(item, at: dest)
    }

    /// 滚动到指定 item
    public func scrollToItem(atIndex index: Int, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        sectionContext?.scrollToItem(atIndex: index, scrollPosition: scrollPosition, animated: animated)
    }

    /// 拉取 Section 数据（子类重写）
    open func fetchSectionData() {}

    /// 加载更多 Section 数据（子类重写）
    open func loadMoreSectionData() {}

    // MARK: - Section Operations

    /// 重新加载当前可见 Section
    public func reloadVisibleSection() {
        sectionContext?.reloadSection(animated: false, completion: nil)
    }

    /// 重新加载当前 Section
    public func reloadCurrentSection() {
        sectionContext?.reloadSection(animated: false, completion: nil)
    }

    /// 重新加载当前 Section（带动画和回调）
    public func reloadCurrentSection(animated: Bool, completion: ((Bool) -> Void)?) {
        sectionContext?.reloadSection(animated: animated, completion: completion)
    }

    /// 增量更新当前 Section
    public func updateCurrentSection() {
        sectionContext?.updateSection(animated: false, completion: nil)
    }

    /// 移除当前 Section
    public func removeCurrentSectionWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let listVM = listContext?.listViewModel() else { return }
        listVM.removeSectionViewModels([self], animated: animated, completion: completion)
    }

    // MARK: - ListSectionViewModelProtocol

    /// 判断是否能处理指定类型的数据
    open class func canHandleData(_ data: Any?) -> Bool {
        false
    }

    /// 根据数据创建 SectionViewModel
    open class func sectionViewModel(forData data: Any, context: ListContext) -> Self {
        fatalError("Subclass must override sectionViewModel(forData:context:)")
    }

    /// 判断是否与指定数据相等
    open func isEqual(toData data: Any) -> Bool {
        guard let model = responseModel else { return false }
        return (model as AnyObject) === (data as AnyObject)
    }

    // MARK: - IGListDiffable

    /// Diff 标识符（使用对象地址）
    open func diffIdentifier() -> any NSObjectProtocol {
        return ObjectIdentifier(self) as AnyObject as! NSObjectProtocol
    }

    /// 判断是否与 Diff 对象相等（使用指针比较）
    open func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        return self === (object as AnyObject)
    }

    // MARK: - Helpers

    /// 移除数组中的重复对象
    static func removeDuplicates(_ objects: [AnyObject]) -> [AnyObject] {
        var seen = Set<ObjectIdentifier>()
        return objects.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }
}
