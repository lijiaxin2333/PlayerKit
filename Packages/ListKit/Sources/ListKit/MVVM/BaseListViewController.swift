import UIKit
import IGListKit

@MainActor
open class BaseListViewController<VM: BaseListViewModel>: UIViewController, ListViewControllerDataSource, ListContainerContext, ListContainerConfig, BaseListFlowLayoutDelegate, ListContext, ListDisplayDelegate, UIScrollViewDelegate {

    public private(set) var listAdapter: IGListKit.ListAdapter?
    public private(set) var baseCollectionView: UICollectionView?

    private var adapterDataSource: ListKitAdapterDataSource?
    private var adapterDelegate: ListKitAdapterDelegate?
    private var adapterUpdaterDelegate: ListKitAdapterUpdaterDelegate?

    public weak var scrollViewDelegate: UIScrollViewDelegate? {
        didSet {
            listAdapter?.scrollViewDelegate = scrollViewDelegate
        }
    }
    public weak var listDisplayDelegate: ListDisplayDelegate? {
        didSet {
            adapterDelegate?.delegate = listDisplayDelegate
        }
    }

    private lazy var _viewModel: VM = {
        let vm = createViewModel()
        vm.containerContext = self
        return vm
    }()

    public var viewModel: VM {
        return _viewModel
    }

    public private(set) lazy var contextProxy: ListContext = {
        ListViewContextProxy(target: self)
    }()

    public var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet {
            baseCollectionView?.contentInset = contentEdgeInsets
        }
    }

    public var defaultFrame: CGRect = .zero

    public var showsScrollIndicator: Bool = true {
        didSet {
            baseCollectionView?.showsVerticalScrollIndicator = showsScrollIndicator
            baseCollectionView?.showsHorizontalScrollIndicator = showsScrollIndicator
        }
    }

    public var enablePullDownRefresh: Bool = true

    private var _isRefreshing: Bool = false
    private var _isLoadingMore: Bool = false
    private var _isScrolling: Bool = false
    private var _isVisible: Bool = false
    private var _loadMoreEnabled: Bool = true

    public var workingRange: Int = 0

    public init(viewModel: VM? = nil) {
        super.init(nibName: nil, bundle: nil)
        if let vm = viewModel {
            _viewModel = vm
            vm.containerContext = self
            vm.updateListContext(self)
        }
    }

    public required init?(coder: NSCoder) { fatalError() }

    open override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        listDisplayDelegate = self
        viewModel.setupViewModel()
        registerAppLifeCycleNotification()
        viewModel.notifyPlugins { $0.viewDidLoad(byViewController: self) }
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _isVisible = true
        adapterDataSource?.notifyWillAppear(animated, isBeingPresented: isBeingPresented, isMovingToParent: isMovingToParent)
        viewModel.notifyPlugins { $0.viewWillAppear(byViewController: self) }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adapterDataSource?.notifyDidAppear(animated)
        viewModel.notifyPlugins { $0.viewDidAppear(byViewController: self) }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _isVisible = false
        adapterDataSource?.notifyWillDisappear(animated, isBeingDismissed: isBeingDismissed, isMovingFromParent: isMovingFromParent)
        viewModel.notifyPlugins { $0.viewWillDisappear(byViewController: self) }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        adapterDataSource?.notifyDidDisappear(animated)
        viewModel.notifyPlugins { $0.viewDidDisappear(byViewController: self) }
    }

    // MARK: - Override Points

    open func createViewModel() -> VM {
        return VM.init()
    }

    open func layoutForCollectionView() -> UICollectionViewLayout {
        let layout = BaseListFlowLayout()
        layout.baseDelegate = self
        return layout
    }

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

        let updater = IGListKit.ListAdapterUpdater()
        updater.delegate = updaterDel

        let wr = self.workingRangeSize()
        let adapter = IGListKit.ListAdapter(updater: updater, viewController: self, workingRangeSize: wr)
        adapter.collectionView = cv
        adapter.dataSource = ds
        adapter.delegate = del
        if let svd = scrollViewDelegate {
            adapter.scrollViewDelegate = svd
        }
        listAdapter = adapter

        setupCollectionView(cv)
    }

    // MARK: - ListViewControllerDataSource

    public func sectionViewModels() -> [BaseListSectionViewModel] {
        viewModel.sectionViewModelsArray
    }

    open func dataSourceDidCreateSectionController(_ sectionController: BaseListSectionController, forSectionViewModel sectionViewModel: BaseListSectionViewModel) {
        sectionController.containerConfig = self
    }

    // MARK: - ListContainerContext

    public func reloadContainer(completion: ((Bool) -> Void)?) {
        listAdapter?.reloadData(completion: { finished in
            completion?(finished)
        })
    }

    public func updateContainer(animated: Bool, completion: ((Bool) -> Void)?) {
        listAdapter?.performUpdates(animated: animated, completion: { finished in
            completion?(finished)
        })
    }

    public func scrollToObject(_ object: AnyObject, supplementaryKinds: [String]?, scrollDirection: UICollectionView.ScrollDirection, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        listAdapter?.scroll(to: object, supplementaryKinds: supplementaryKinds, scrollDirection: scrollDirection, scrollPosition: scrollPosition, additionalOffset: 0, animated: animated)
    }

    public func visibleSectionViewModels() -> [BaseListSectionViewModel] {
        (listAdapter?.visibleObjects() as? [BaseListSectionViewModel]) ?? []
    }

    // MARK: - ListBaseInfo

    public func baseListViewController() -> UIViewController? {
        self
    }

    public func cellSizeCached() -> Bool {
        viewModel.cellSizeCached()
    }

    public func listUserInfo() -> [String: Any]? {
        viewModel.listUserInfo()
    }

    public func sectionViewModelFromData(_ data: Any) -> BaseListSectionViewModel? {
        viewModel.createSectionViewModel(forData: data)
    }

    public func sectionController(forSection section: Int) -> BaseListSectionController? {
        sectionController(atIndex: section)
    }

    public func sectionController(forSectionViewModel sectionViewModel: BaseListSectionViewModel) -> BaseListSectionController? {
        sectionController(forViewModel: sectionViewModel)
    }

    public func addDisposableRequestInfo(_ requestInfo: [String: Any]) {
        viewModel.addDisposableRequestInfo(requestInfo)
    }

    public func listViewModel() -> BaseListViewModel? {
        viewModel
    }

    public func registerListObserver(_ observer: AnyObject) {
        viewModel.registerListObserver(observer)
    }

    public func removeListObserver(_ observer: AnyObject) {
        viewModel.removeListObserver(observer)
    }

    public func responderForProtocol<T>(_ protocolType: T.Type) -> T? {
        viewModel.responderForProtocol(protocolType)
    }

    // MARK: - ListUIInfo

    public func scrollView() -> UIScrollView? {
        baseCollectionView
    }

    public func visibleSectionControllers() -> [BaseListSectionController] {
        guard let adapter = listAdapter else { return [] }
        return adapter.visibleObjects().compactMap { obj in
            adapter.sectionController(for: obj) as? BaseListSectionController
        }
    }

    public func isRefreshing() -> Bool {
        _isRefreshing
    }

    public func isLoadingMore() -> Bool {
        _isLoadingMore
    }

    public func isScrolling() -> Bool {
        _isScrolling
    }

    public func isVisible() -> Bool {
        _isVisible
    }

    public func loadMoreEnabled() -> Bool {
        _loadMoreEnabled
    }

    public func isViewLoaded() -> Bool {
        isViewLoaded
    }

    public func containerSize() -> CGSize {
        baseCollectionView?.bounds.size ?? .zero
    }

    public func containerView() -> UIView? {
        view
    }

    public func listContentOffset() -> CGPoint {
        baseCollectionView?.contentOffset ?? .zero
    }

    public func listContentInset() -> UIEdgeInsets {
        baseCollectionView?.contentInset ?? .zero
    }

    public func listContentSize() -> CGSize {
        baseCollectionView?.contentSize ?? .zero
    }

    public func rect(forSection section: Int) -> CGRect {
        guard let cv = baseCollectionView,
              let layout = cv.collectionViewLayout as? UICollectionViewFlowLayout else { return .zero }
        return layout.layoutAttributesForItem(at: IndexPath(item: 0, section: section))?.frame ?? .zero
    }

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

    // MARK: - UIScrollViewDelegate

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _isScrolling = true
        viewModel.notifyPlugins { $0.scrollViewDidScroll(scrollView) }
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
