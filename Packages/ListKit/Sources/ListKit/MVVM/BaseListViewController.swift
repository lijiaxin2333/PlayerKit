import UIKit
import IGListKit

@MainActor
open class BaseListViewController<VM: BaseListViewModel>: UIViewController,
                                                            ListViewControllerDataSource,
                                                            ListContainerContext,
                                                            ListContainerConfig,
                                                            BaseListFlowLayoutDelegate,
                                                            ListContext,
                                                            ListDisplayDelegate,
                                                            ListScrollViewDelegate {

    /*
     列表核心协调器
     负责: 数据管理, sectioncontroller创建, diff计算, 批量更新, CollectionView桥接
     */
    public private(set) var listAdapter: IGListKit.ListAdapter?
    
    /*
     承接列表的CollectionView
     */
    public private(set) var baseCollectionView: UICollectionView?

    // MARK: IGListKit桥接层
    
    /*
     提供 Section 数据、创建 SectionController、分发 ViewController 生命周期给 SectionController
     */
    private var adapterDataSource: ListKitAdapterDataSource?
    
    /*
     转发 Section 显隐事件 (willDisplay/didEndDisplaying)
     */
    private var adapterDelegate: ListKitAdapterDelegate?
    
    /*
     监听列表数据更新事件（批量更新完成、reloadData 等）
     */
    private var adapterUpdaterDelegate: ListKitAdapterUpdaterDelegate?
    
    /*
     转发滚动事件，支持外部注入额外代理
     */
    private var adapterScrollViewDelegate: ListKitAdapterScrollViewDelegate? // 列表: 滚动事件

    /*
     外部注入的滚动代理，接收所有滚动回调
     */
    public weak var scrollViewDelegate: UIScrollViewDelegate? {
        didSet {
            adapterScrollViewDelegate?.externalDelegate = scrollViewDelegate
        }
    }

    /*
     外部注入的 Section 显隐代理
     */
    public weak var listDisplayDelegate: ListDisplayDelegate? {
        didSet {
            adapterDelegate?.delegate = listDisplayDelegate
        }
    }

    /*
     内部持有的 ViewModel 实例
     */
    private lazy var _viewModel: VM = {
        let vm = createViewModel()
        vm.containerContext = self
        return vm
    }()

    /*
     对外暴露的 ViewModel 访问入口
     */
    public var viewModel: VM {
        return _viewModel
    }

    /*
     ListContext 的代理包装，用于传递上下文
     */
    public private(set) lazy var contextProxy: ListContext = {
        ListViewContextProxy(target: self)
    }()

    /*
     列表内容边距
     */
    public var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            baseCollectionView?.contentInset = contentEdgeInsets
        }
    }

    /*
     默认 Frame ???
     */
    public var defaultFrame: CGRect = .zero

    /*
     是否显示滚动条
     */
    public var showsScrollIndicator: Bool = true {
        didSet {
            baseCollectionView?.showsVerticalScrollIndicator = showsScrollIndicator
            baseCollectionView?.showsHorizontalScrollIndicator = showsScrollIndicator
        }
    }

    /*
     是否启用下拉刷新
     */
    public var enablePullDownRefresh: Bool = true

    /*
     当前是否在下拉刷新
     当前是否在加载更多
     当前是否在滚动
     ViewController 是否可见
     是否启用加载更多
     */
    private var _isRefreshing: Bool = false
    private var _isLoadingMore: Bool = false
    private var _isScrolling: Bool = false
    private var _isVisible: Bool = false
    private var _loadMoreEnabled: Bool = true

    /*
     预加载范围
     */
    public var workingRange: Int = 0

    /*
     初始化，支持外部注入 ViewModel
     */
    public init(viewModel: VM? = nil) {
        super.init(nibName: nil, bundle: nil)
        if let vm = viewModel {
            _viewModel = vm
            vm.containerContext = self
            vm.updateListContext(self)
        }
    }

    public required init?(coder: NSCoder) { fatalError() }

    /*
     设置 CollectionView、注册 App 生命周期通知、通知 Plugin
     */
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        listDisplayDelegate = self
        viewModel.setupViewModel()
        registerAppLifeCycleNotification()
        viewModel.notifyPlugins { $0.viewDidLoad(byViewController: self) }
    }

    /*
     更新可见状态、通知 SectionController 和 Plugin
     */
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _isVisible = true
        adapterDataSource?.notifyWillAppear(animated, isBeingPresented: isBeingPresented, isMovingToParent: isMovingToParent)
        viewModel.notifyPlugins { $0.viewWillAppear(byViewController: self) }
    }

    /*
     通知 SectionController 和 Plugin
     */
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adapterDataSource?.notifyDidAppear(animated)
        viewModel.notifyPlugins { $0.viewDidAppear(byViewController: self) }
    }

    /*
     更新可见状态、通知 SectionController 和 Plugin
     */
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _isVisible = false
        adapterDataSource?.notifyWillDisappear(animated, isBeingDismissed: isBeingDismissed, isMovingFromParent: isMovingFromParent)
        viewModel.notifyPlugins { $0.viewWillDisappear(byViewController: self) }
    }

    /*
     更新可见状态、通知 SectionController 和 Plugin
     */
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        adapterDataSource?.notifyDidDisappear(animated)
        viewModel.notifyPlugins { $0.viewDidDisappear(byViewController: self) }
    }

    // MARK: - Override Points

    /*
     子类重写，创建默认 ViewModel
     */
    open func createViewModel() -> VM {
        return VM.init()
    }

    /*
     子类重写，返回自定义 Layout
     */
    open func layoutForCollectionView() -> UICollectionViewLayout {
        let layout = BaseListFlowLayout()
        layout.baseDelegate = self
        return layout
    }

    /*
     子类重写，对 CollectionView 进行额外配置
     */
    open func setupCollectionView(_ collectionView: UICollectionView) {}

    // MARK: - ListContainerConfig

    public var separatorConfig: ListSeparatorConfig {
        viewModel.separatorConfig
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let layout = layoutForCollectionView()
        if let flowLayout = layout as? BaseListFlowLayout {
            flowLayout.baseDelegate = self
        }

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .black
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.contentInsetAdjustmentBehavior = .never
        view.addSubview(cv)
        baseCollectionView = cv

        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: view.topAnchor),
            cv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let ds = ListKitAdapterDataSource(viewController: self)
        ds.dataSource = self
        adapterDataSource = ds

        let del = ListKitAdapterDelegate()
        del.delegate = listDisplayDelegate
        adapterDelegate = del

        let updaterDel = ListKitAdapterUpdaterDelegate(viewController: self)
        adapterUpdaterDelegate = updaterDel

        let scrollDel = ListKitAdapterScrollViewDelegate()
        scrollDel.delegate = self
        adapterScrollViewDelegate = scrollDel

        let updater = IGListKit.ListAdapterUpdater()
        updater.delegate = updaterDel

        let wr = self.workingRangeSize()
        let adapter = IGListKit.ListAdapter(updater: updater, viewController: self, workingRangeSize: wr)
        adapter.collectionView = cv
        adapter.dataSource = ds
        adapter.delegate = del
        adapter.scrollViewDelegate = scrollDel
        listAdapter = adapter

        setupCollectionView(cv)
    }

    // MARK: - ListViewControllerDataSource

    /*
     返回当前所有 SectionViewModel
     */
    public func sectionViewModels() -> [BaseListSectionViewModel] {
        viewModel.sectionViewModelsArray
    }

    /*
     SectionController 创建后的回调，设置 containerConfig
     */
    open func dataSourceDidCreateSectionController(_ sectionController: BaseListSectionController, forSectionViewModel sectionViewModel: BaseListSectionViewModel) {
        sectionController.containerConfig = self
    }

    // MARK: - ListContainerContext

    /*
     完全重载列表
     */
    public func reloadContainer(completion: ((Bool) -> Void)?) {
        listAdapter?.reloadData(completion: { finished in
            completion?(finished)
        })
    }

    /*
     增量更新列表
     */
    public func updateContainer(animated: Bool, completion: ((Bool) -> Void)?) {
        listAdapter?.performUpdates(animated: animated, completion: { finished in
            completion?(finished)
        })
    }

    /*
     滚动到指定对象
     */
    public func scrollToObject(_ object: AnyObject, supplementaryKinds: [String]?, scrollDirection: UICollectionView.ScrollDirection, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        listAdapter?.scroll(to: object, supplementaryKinds: supplementaryKinds, scrollDirection: scrollDirection, scrollPosition: scrollPosition, additionalOffset: 0, animated: animated)
    }

    /*
     获取当前可见的 SectionViewModel
     */
    public func visibleSectionViewModels() -> [BaseListSectionViewModel] {
        (listAdapter?.visibleObjects() as? [BaseListSectionViewModel]) ?? []
    }

    // MARK: - ListBaseInfo

    /*
     返回 ViewController 自身
     */
    public func baseListViewController() -> UIViewController? {
        self
    }

    /*
     是否缓存 Cell 尺寸
     */
    public func cellSizeCached() -> Bool {
        viewModel.cellSizeCached()
    }

    /*
     用户自定义信息
     */
    public func listUserInfo() -> [String: Any]? {
        viewModel.listUserInfo()
    }

    /*
     从数据创建 SectionViewModel
     */
    public func sectionViewModelFromData(_ data: Any) -> BaseListSectionViewModel? {
        viewModel.createSectionViewModel(forData: data)
    }

    /*
     根据索引获取 SectionController
     */
    public func sectionController(forSection section: Int) -> BaseListSectionController? {
        sectionController(atIndex: section)
    }

    /*
     根据 ViewModel 获取 SectionController
     */
    public func sectionController(forSectionViewModel sectionViewModel: BaseListSectionViewModel) -> BaseListSectionController? {
        sectionController(forViewModel: sectionViewModel)
    }

    /*
     添加可销毁的请求信息
     */
    public func addDisposableRequestInfo(_ requestInfo: [String: Any]) {
        viewModel.addDisposableRequestInfo(requestInfo)
    }

    /*
     返回 ViewModel
     */
    public func listViewModel() -> BaseListViewModel? {
        viewModel
    }

    /*
     注册列表观察者
     */
    public func registerListObserver(_ observer: AnyObject) {
        viewModel.registerListObserver(observer)
    }

    /*
     移除列表观察者
     */
    public func removeListObserver(_ observer: AnyObject) {
        viewModel.removeListObserver(observer)
    }

    /*
     根据协议类型查找响应者
     */
    public func responderForProtocol<T>(_ protocolType: T.Type) -> T? {
        viewModel.responderForProtocol(protocolType)
    }

    // MARK: - ListUIInfo

    /*
     返回 CollectionView（作为 ScrollView）
     */
    public func scrollView() -> UIScrollView? {
        baseCollectionView
    }

    /*
     获取所有可见的 SectionController
     */
    public func visibleSectionControllers() -> [BaseListSectionController] {
        guard let adapter = listAdapter else { return [] }
        return adapter.visibleObjects().compactMap { obj in
            adapter.sectionController(for: obj) as? BaseListSectionController
        }
    }

    /*
     当前是否刷新中
     */
    public func isRefreshing() -> Bool {
        _isRefreshing
    }

    /*
     当前是否加载更多中
     */
    public func isLoadingMore() -> Bool {
        _isLoadingMore
    }

    /*
     当前是否滚动中
     */
    public func isScrolling() -> Bool {
        _isScrolling
    }

    /*
     ViewController 是否可见
     */
    public func isVisible() -> Bool {
        _isVisible
    }

    /*
     是否启用加载更多
     */
    public func loadMoreEnabled() -> Bool {
        _loadMoreEnabled
    }

    /*
     View 是否已加载
     */
    public func isViewLoaded() -> Bool {
        isViewLoaded
    }

    /*
     容器尺寸
     */
    public func containerSize() -> CGSize {
        baseCollectionView?.bounds.size ?? .zero
    }

    /*
     容器 View
     */
    public func containerView() -> UIView? {
        view
    }

    /*
     内容偏移
     */
    public func listContentOffset() -> CGPoint {
        baseCollectionView?.contentOffset ?? .zero
    }

    /*
     内容边距
     */
    public func listContentInset() -> UIEdgeInsets {
        baseCollectionView?.contentInset ?? .zero
    }

    /*
     内容尺寸
     */
    public func listContentSize() -> CGSize {
        baseCollectionView?.contentSize ?? .zero
    }

    /*
     获取指定 Section 的 Frame
     */
    public func rect(forSection section: Int) -> CGRect {
        guard let cv = baseCollectionView,
              let layout = cv.collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        return layout.layoutAttributesForItem(at: IndexPath(item: 0, section: section))?.frame ?? .zero
    }

    /*
     获取指定 View 相对于 CollectionView 的 Frame
     */
    public func rect(forView view: UIView) -> CGRect {
        guard let cv = baseCollectionView else { return .zero }
        return view.convert(view.bounds, to: cv)
    }

    // MARK: - ListOperation

    public func cancelRequestIfNeeded() {
    }

    public func clearList() {
        viewModel.reloadBySectionViewModels([])
    }

    public func updateListIfNeeded() {
        performUpdates(animated: false)
    }

    public func updateListWithDataSourceIfNeeded() {
        updateListWithDataSourceIfNeeded(completion: nil)
    }

    public func updateListWithDataSourceIfNeeded(completion: (() -> Void)?) {
        performUpdates(animated: false) { _ in
            completion?()
        }
    }

    public func clearAllCellSizeCaches() {
    }

    public func triggerPullDownRefreshIfNeeded() {
        triggerPullDownRefreshIfNeeded(contextInfo: nil)
    }

    public func triggerPullDownRefreshIfNeeded(contextInfo: [String: Any]?) {
        guard enablePullDownRefresh else { return }
        _isRefreshing = true
        viewModel.fetchListData()
    }

    public func triggerPullUpLoadMoreIfNeeded() {
        guard _loadMoreEnabled else { return }
        _isLoadingMore = true
        viewModel.loadMoreListData()
    }

    @discardableResult
    public func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel
    ) -> Bool {
        replaceSectionViewModel(sectionViewModel, with: newSectionViewModel, animated: false, completion: nil)
    }

    @discardableResult
    public func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel,
        animated: Bool,
        completion: ((Bool) -> Void)?
    ) -> Bool {
        guard let index = viewModel.sectionViewModelsArray.firstIndex(where: { $0 === sectionViewModel }) else {
            return false
        }
        viewModel.sectionViewModelsArray[index] = newSectionViewModel
        performUpdates(animated: animated, completion: completion)
        return true
    }

    public func scrollToTop(animated: Bool) {
        baseCollectionView?.setContentOffset(.zero, animated: animated)
    }

    public func scrollToSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        scrollPosition: UICollectionView.ScrollPosition,
        animated: Bool
    ) {
        scrollToObject(sectionViewModel, supplementaryKinds: nil, scrollDirection: .vertical, scrollPosition: scrollPosition, animated: animated)
    }

    public func scrollToContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        baseCollectionView?.setContentOffset(contentOffset, animated: animated)
    }

    // MARK: - ListNotification

    public func registerObserver(
        _ observer: AnyObject,
        actionBlock: @escaping (_ object: Any?, _ userInfo: Any?) -> Void,
        name: ListMsgName
    ) {
        viewModel.registerMsgObserver(observer, actionBlock: actionBlock, name: name)
    }

    public func removeObserver(_ observer: AnyObject, name: ListMsgName) {
        viewModel.removeMsgObserver(observer, name: name)
    }

    public func postMsgName(_ name: ListMsgName, object: Any?) {
        viewModel.postMsg(name, object: object, userInfo: nil)
    }

    public func postMsgName(_ name: ListMsgName, object: Any?, userInfo: [String: Any]?) {
        viewModel.postMsg(name, object: object, userInfo: userInfo)
    }

    // MARK: - State Update

    public func setRefreshing(_ refreshing: Bool) {
        _isRefreshing = refreshing
    }

    public func setLoadingMore(_ loadingMore: Bool) {
        _isLoadingMore = loadingMore
    }

    public func setScrolling(_ scrolling: Bool) {
        _isScrolling = scrolling
    }

    public func setLoadMoreEnabled(_ enabled: Bool) {
        _loadMoreEnabled = enabled
    }

    // MARK: - BaseListFlowLayoutDelegate

    public func backgroundColorAtSectionIndex(_ sectionIndex: Int) -> UIColor? {
        guard let sc = sectionController(atIndex: sectionIndex) else { return nil }
        return sc.sectionBackgroundColor()
    }

    public func shouldStickHeaderAtSectionIndex(_ sectionIndex: Int) -> Bool {
        guard let sc = sectionController(atIndex: sectionIndex) else { return false }
        return shouldStickHeader(atSectionIndex: sectionIndex, sectionController: sc)
    }

    public func sectionBackgroundViewDidLayout(_ view: UIView, atSectionIndex sectionIndex: Int) {
        sectionController(atIndex: sectionIndex)?.sectionBackgroundViewDidLayout(view)
    }

    // MARK: - Helpers

    public func sectionController(atIndex index: Int) -> BaseListSectionController? {
        listAdapter?.sectionController(forSection: index) as? BaseListSectionController
    }

    public func sectionController(forViewModel viewModel: BaseListSectionViewModel) -> BaseListSectionController? {
        listAdapter?.sectionController(for: viewModel) as? BaseListSectionController
    }

    public func reloadList(completion: ((Bool) -> Void)? = nil) {
        listAdapter?.reloadData(completion: { finished in
            completion?(finished)
        })
    }

    public func reloadSectionViewModels(_ viewModels: [BaseListSectionViewModel]) {
        guard !viewModels.isEmpty else { return }
        listAdapter?.reloadObjects(viewModels)
    }

    public func performUpdates(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        listAdapter?.performUpdates(animated: animated, completion: { finished in
            completion?(finished)
        })
    }

    // MARK: - App LifeCycle

    private func registerAppLifeCycleNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func handleAppDidEnterBackground() {
        adapterDataSource?.notifyAppDidEnterBackground()
    }

    @objc private func handleAppWillEnterForeground() {
        adapterDataSource?.notifyAppWillEnterForeground()
    }

    // MARK: - ListDisplayDelegate

    open func listWillDisplaySectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int) {
        let duplicateReload = sectionViewModel.isVisible
        sectionViewModel.updateVisibility(true)
        (sectionViewModel as? ListSectionViewModelProtocol)?.sectionViewModelWillDisplay(duplicateReload: duplicateReload)
        viewModel.notifyPlugins { $0.sectionViewModelWillDisplay(sectionViewModel, forIndex: index, duplicateReload: duplicateReload) }
    }

    open func listDidEndDisplayingSectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int) {
        let visibleSections = baseCollectionView?.indexPathsForVisibleItems.map { $0.section } ?? []
        if !visibleSections.contains(index) {
            sectionViewModel.updateVisibility(false)
        }
        let duplicateReload = sectionViewModel.isVisible
        (sectionViewModel as? ListSectionViewModelProtocol)?.sectionViewModelDidEndDisplaying(duplicateReload: duplicateReload)
        viewModel.notifyPlugins { $0.sectionViewModelDidEndDisplaying(sectionViewModel, forIndex: index, duplicateReload: duplicateReload) }
    }

    // MARK: - ListScrollViewDelegate

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _isScrolling = true
        viewModel.notifyPlugins { $0.scrollViewDidScroll(scrollView) }
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.notifyPlugins { $0.scrollViewWillBeginDragging(scrollView) }
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        viewModel.notifyPlugins { $0.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) }
    }

    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        viewModel.notifyPlugins { $0.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate) }
        if !decelerate {
            _isScrolling = false
            viewModel.notifyPlugins { $0.scrollViewDidEndScrolling() }
        }
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _isScrolling = false
        viewModel.notifyPlugins { $0.scrollViewDidEndDecelerating(scrollView) }
        viewModel.notifyPlugins { $0.scrollViewDidEndScrolling() }
    }

    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _isScrolling = false
        viewModel.notifyPlugins { $0.scrollViewDidEndScrollingAnimation(scrollView) }
    }
}
