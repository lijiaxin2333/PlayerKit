import UIKit

@MainActor
open class BaseListViewModel: ListBaseInfo {

    public var sectionViewModelsArray: [BaseListSectionViewModel] = []
    public var separatorConfig: ListSeparatorConfig = ListSeparatorConfig()

    public weak var containerContext: ListContainerContext?

    public var dataSourceState: ListDataSourceState = .none
    public var dataSourceHasMore: Bool = false
    public var refreshState: ListDataLoadState = .isNotLoading
    public var loadMoreState: ListDataLoadState = .isNotLoading
    public var errorMessage: String = ""

    public private(set) weak var listContext: ListContext?

    public var cellSizeCached_: Bool = false
    public var disableReloadWithExistDataWhenSetupViewModel: Bool = false
    public var allowDataMismatch: Bool = false

    private var registeredSectionViewModelClasses: [(cls: BaseListSectionViewModel.Type, desc: String)] = []
    private var businessPlugins: [AnyObject] = []
    private var protocolMapping: [ObjectIdentifier: AnyObject] = [:]
    private var listObservers: NSHashTable<AnyObject> = NSHashTable.weakObjects()
    private var listUserInfo_: [String: Any]?
    private var disposableRequestInfo: [String: Any]?
    private var msgObservers: [ListMsgName: NSMapTable<AnyObject, ListMsgActionWrapper>] = [:]

    public required init() {}

    open func setupViewModel() {}
    open func fetchListData() {}
    open func loadMoreListData() {}

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

    open func registerSectionViewModelClass(_ sectionViewModelClass: BaseListSectionViewModel.Type, description: String) {
        registeredSectionViewModelClasses.append((cls: sectionViewModelClass, desc: description))
    }

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

    open func removeAllBusinessPlugins() {
        for plugin in businessPlugins {
            if var p = plugin as? ListPluginProtocol {
                p.listContext = nil
            }
        }
        businessPlugins.removeAll()
        protocolMapping.removeAll()
    }

    open func registerListUserInfo(_ userInfo: [String: Any]) {
        listUserInfo_ = userInfo
    }

    // MARK: - Operations

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

    open func updateBySectionViewModels(_ viewModels: [BaseListSectionViewModel], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: viewModels)
        if sectionViewModelsArray.isEmpty && viewModels.isEmpty {
            completion?(true)
            return
        }
        sectionViewModelsArray = viewModels
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

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

    public func removeSectionViewModels(_ viewModels: [BaseListSectionViewModel], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !viewModels.isEmpty else {
            completion?(true)
            return
        }
        sectionViewModelsArray.removeAll { vm in viewModels.contains(where: { $0 === vm }) }
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    open func insertSectionViewModel(_ viewModel: BaseListSectionViewModel, atIndex index: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        bindListContext(to: [viewModel])
        guard index <= sectionViewModelsArray.count else {
            completion?(true)
            return
        }
        sectionViewModelsArray.insert(viewModel, at: index)
        containerContext?.updateContainer(animated: animated, completion: completion)
    }

    public func scrollToSectionViewModel(_ viewModel: BaseListSectionViewModel, supplementaryKinds: [String]? = nil, scrollDirection: UICollectionView.ScrollDirection, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        containerContext?.scrollToObject(viewModel, supplementaryKinds: supplementaryKinds, scrollDirection: scrollDirection, scrollPosition: scrollPosition, animated: animated)
    }

    public var visibleSectionViewModels: [BaseListSectionViewModel] {
        containerContext?.visibleSectionViewModels() ?? []
    }

    private func bindListContext(to viewModels: [BaseListSectionViewModel]) {
        for vm in viewModels {
            vm.updateListContext(listContext)
        }
    }

    // MARK: - SectionViewModel Factory

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

    public func removeMsgObserver(_ observer: AnyObject, name: ListMsgName) {
        msgObservers[name]?.removeObject(forKey: observer)
    }

    public func postMsg(_ name: ListMsgName, object: Any?, userInfo: [String: Any]?) {
        guard let table = msgObservers[name] else { return }
        let enumerator = table.objectEnumerator()
        while let wrapper = enumerator?.nextObject() as? ListMsgActionWrapper {
            wrapper.block(object, userInfo)
        }
    }

    func consumeDisposableRequestInfo() -> [String: Any]? {
        let info = disposableRequestInfo
        disposableRequestInfo = nil
        return info
    }
}

final class ListMsgActionWrapper: NSObject {
    let block: (_ object: Any?, _ userInfo: Any?) -> Void

    init(block: @escaping (_ object: Any?, _ userInfo: Any?) -> Void) {
        self.block = block
    }
}
