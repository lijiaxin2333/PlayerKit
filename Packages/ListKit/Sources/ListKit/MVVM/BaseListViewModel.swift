import UIKit

/// 列表 ViewModel 基类
/// - 职责:
///   1. 管理 SectionViewModel 数组
///   2. 管理数据状态（刷新、加载更多、错误等）
///   3. 管理 Plugin 和 Observer
///   4. 提供消息通知机制
/// - 子类: 业务层 ViewModel
@MainActor
open class BaseListViewModel: ListBaseInfo {

    // MARK: - Data

    /// SectionViewModel 数组
    public var sectionViewModelsArray: [BaseListSectionViewModel] = []

    /// 分隔线配置
    public var separatorConfig: ListSeparatorConfig = ListSeparatorConfig()

    // MARK: - Context

    /// 容器上下文
    public weak var containerContext: ListContainerContext?

    /// 列表上下文
    public private(set) weak var listContext: ListContext?

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

    // MARK: - Configuration

    /// 是否缓存 Cell 尺寸
    public var cellSizeCached_: Bool = false

    /// 是否禁用已有数据时重新加载
    public var disableReloadWithExistDataWhenSetupViewModel: Bool = false

    /// 是否允许数据不匹配
    public var allowDataMismatch: Bool = false

    // MARK: - Private

    /// 注册的 SectionViewModel 类型
    private var registeredSectionViewModelClasses: [(cls: BaseListSectionViewModel.Type, desc: String)] = []

    /// 业务 Plugin 数组
    private var businessPlugins: [AnyObject] = []

    /// 协议映射表
    private var protocolMapping: [ObjectIdentifier: AnyObject] = [:]

    /// 列表观察者
    private var listObservers: NSHashTable<AnyObject> = NSHashTable.weakObjects()

    /// 用户自定义信息
    private var listUserInfo_: [String: Any]?

    /// 可销毁的请求信息
    private var disposableRequestInfo: [String: Any]?

    /// 消息观察者表
    private var msgObservers: [ListMsgName: NSMapTable<AnyObject, ListMsgActionWrapper>] = [:]

    public required init() {}

    // MARK: - Override Points

    /// 初始化 ViewModel（子类重写）
    open func setupViewModel() {}

    /// 拉取列表数据（子类重写）
    open func fetchListData() {}

    /// 加载更多列表数据（子类重写）
    open func loadMoreListData() {}

    /// 更新列表上下文
    public func updateListContext(_ context: ListContext?) {
        self.listContext = context
        for plugin in businessPlugins {
            if var p = plugin as? ListPluginProtocol {
                p.listContext = context
                p.listContextDidLoad()
            }
        }
    }

    // MARK: - Registration

    /// 注册 SectionViewModel 类型
    open func registerSectionViewModelClass(_ sectionViewModelClass: BaseListSectionViewModel.Type, description: String) {
        registeredSectionViewModelClasses.append((cls: sectionViewModelClass, desc: description))
    }

    /// 注册业务 Plugin
    open func registerBusinessPlugin(_ plugin: AnyObject) {
        guard let p = plugin as? ListPluginProtocol else { return }
        businessPlugins.append(plugin)
        for proto in p.implementProtocols() {
            protocolMapping[ObjectIdentifier(proto)] = plugin
        }
        if var mp = plugin as? ListPluginProtocol, let ctx = listContext {
            mp.listContext = ctx
            mp.listContextDidLoad()
        }
    }

    /// 移除所有业务 Plugin
    open func removeAllBusinessPlugins() {
        for plugin in businessPlugins {
            if var p = plugin as? ListPluginProtocol {
                p.listContext = nil
            }
        }
        businessPlugins.removeAll()
        protocolMapping.removeAll()
    }

    /// 注册用户自定义信息
    open func registerListUserInfo(_ userInfo: [String: Any]) {
        listUserInfo_ = userInfo
    }

    // MARK: - Operations

    /// 重新加载数据（完全替换）
    open func reloadBySectionViewModels(_ viewModels: [BaseListSectionViewModel], completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: viewModels)
        let preSectionViewModels = sectionViewModelsArray
        if sectionViewModelsArray.isEmpty && viewModels.isEmpty {
            completion?(true)
            return
        }
        sectionViewModelsArray = viewModels
        notifyPlugins { $0.listWillReloadSectionViewModels(viewModels, preSectionViewModels: preSectionViewModels) }
        containerContext?.reloadContainer(completion: { [weak self] finished in
            self?.notifyPlugins { $0.listDidReloadSectionViewModels(viewModels, preSectionViewModels: preSectionViewModels) }
            completion?(finished)
        })
    }

    /// 增量更新数据
    open func updateBySectionViewModels(_ viewModels: [BaseListSectionViewModel], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: viewModels)
        if sectionViewModelsArray.isEmpty && viewModels.isEmpty {
            completion?(true)
            return
        }
        sectionViewModelsArray = viewModels
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    /// 追加数据
    open func appendSectionViewModels(_ viewModels: [BaseListSectionViewModel], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: viewModels)
        guard !viewModels.isEmpty else {
            completion?(true)
            return
        }
        let preSectionViewModels = sectionViewModelsArray
        if sectionViewModelsArray.isEmpty {
            sectionViewModelsArray = viewModels
            notifyPlugins { $0.listWillReloadSectionViewModels(viewModels, preSectionViewModels: preSectionViewModels) }
            containerContext?.reloadContainer(completion: { [weak self] finished in
                self?.notifyPlugins { $0.listDidReloadSectionViewModels(viewModels, preSectionViewModels: preSectionViewModels) }
                completion?(finished)
            })
            return
        }
        sectionViewModelsArray.append(contentsOf: viewModels)
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    /// 移除数据
    public func removeSectionViewModels(_ viewModels: [BaseListSectionViewModel], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !viewModels.isEmpty else {
            completion?(true)
            return
        }
        sectionViewModelsArray.removeAll { vm in viewModels.contains(where: { $0 === vm }) }
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    /// 插入数据到指定位置
    open func insertSectionViewModel(_ viewModel: BaseListSectionViewModel, atIndex index: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: [viewModel])
        guard index <= sectionViewModelsArray.count else {
            completion?(true)
            return
        }
        sectionViewModelsArray.insert(viewModel, at: index)
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    /// 滚动到指定 Section
    public func scrollToSectionViewModel(_ viewModel: BaseListSectionViewModel, supplementaryKinds: [String]? = nil, scrollDirection: UICollectionView.ScrollDirection, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        containerContext?.scrollToObject(viewModel, supplementaryKinds: supplementaryKinds, scrollDirection: scrollDirection, scrollPosition: scrollPosition, animated: animated)
    }

    /// 获取可见的 SectionViewModel
    public var visibleSectionViewModels: [BaseListSectionViewModel] {
        containerContext?.visibleSectionViewModels() ?? []
    }

    /// 绑定列表上下文到 SectionViewModel
    private func bindListContext(to viewModels: [BaseListSectionViewModel]) {
        for vm in viewModels {
            vm.updateListContext(listContext)
        }
    }

    // MARK: - SectionViewModel Factory

    /// 根据数据创建 SectionViewModel
    public func createSectionViewModel(forData data: Any) -> BaseListSectionViewModel? {
        guard let ctx = listContext else { return nil }
        for entry in registeredSectionViewModelClasses {
            if entry.cls.canHandleData(data) {
                return entry.cls.sectionViewModel(forData: data, context: ctx)
            }
        }
        return nil
    }

    // MARK: - Plugin Notification

    /// 通知所有 Plugin
    public func notifyPlugins(_ action: (ListProtocol) -> Void) {
        for plugin in businessPlugins {
            if let p = plugin as? ListProtocol {
                action(p)
            }
        }
        for observer in listObservers.allObjects {
            if let p = observer as? ListProtocol {
                action(p)
            }
        }
    }

    // MARK: - ListBaseInfo

    public func baseListViewController() -> UIViewController? {
        listContext?.baseListViewController()
    }

    public func cellSizeCached() -> Bool {
        cellSizeCached_
    }

    public func listUserInfo() -> [String: Any]? {
        listUserInfo_
    }

    public func sectionViewModelFromData(_ data: Any) -> BaseListSectionViewModel? {
        createSectionViewModel(forData: data)
    }

    public func sectionController(forSection section: Int) -> BaseListSectionController? {
        listContext?.sectionController(forSection: section)
    }

    public func sectionController(forSectionViewModel sectionViewModel: BaseListSectionViewModel) -> BaseListSectionController? {
        listContext?.sectionController(forSectionViewModel: sectionViewModel)
    }

    public func addDisposableRequestInfo(_ requestInfo: [String: Any]) {
        if disposableRequestInfo == nil {
            disposableRequestInfo = [:]
        }
        for (key, value) in requestInfo {
            disposableRequestInfo?[key] = value
        }
    }

    public func listViewModel() -> BaseListViewModel? {
        self
    }

    public func registerListObserver(_ observer: AnyObject) {
        listObservers.add(observer)
    }

    public func removeListObserver(_ observer: AnyObject) {
        listObservers.remove(observer)
    }

    public func responderForProtocol<T>(_ protocolType: T.Type) -> T? {
        protocolMapping[ObjectIdentifier(protocolType)] as? T
    }

    // MARK: - Message Notification

    /// 注册消息观察者
    public func registerMsgObserver(
        _ observer: AnyObject,
        actionBlock: @escaping (_ object: Any?, _ userInfo: Any?) -> Void,
        name: ListMsgName
    ) {
        var table = msgObservers[name]
        if table == nil {
            table = NSMapTable.weakToStrongObjects()
            msgObservers[name] = table
        }
        let wrapper = ListMsgActionWrapper(block: actionBlock)
        table?.setObject(wrapper, forKey: observer)
    }

    /// 移除消息观察者
    public func removeMsgObserver(_ observer: AnyObject, name: ListMsgName) {
        msgObservers[name]?.removeObject(forKey: observer)
    }

    /// 发送消息
    public func postMsg(_ name: ListMsgName, object: Any?, userInfo: [String: Any]?) {
        guard let table = msgObservers[name] else { return }
        let enumerator = table.objectEnumerator()
        while let wrapper = enumerator?.nextObject() as? ListMsgActionWrapper {
            wrapper.block(object, userInfo)
        }
    }

    /// 消费可销毁的请求信息
    func consumeDisposableRequestInfo() -> [String: Any]? {
        let info = disposableRequestInfo
        disposableRequestInfo = nil
        return info
    }
}

/// 消息动作包装器
final class ListMsgActionWrapper: NSObject {
    let block: (_ object: Any?, _ userInfo: Any?) -> Void

    init(block: @escaping (_ object: Any?, _ userInfo: Any?) -> Void) {
        self.block = block
    }
}
