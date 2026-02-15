import UIKit

/// ListContext 代理类
/// - 职责: 作为 ListContext 的代理包装，将所有调用转发给目标对象
/// - 用途: 用于在需要传递 ListContext 但又不想直接持有引用的场景
@MainActor
public final class ListViewContextProxy: ListContext {

    /// 代理目标
    private weak var target: ListContext?

    public init(target: ListContext) {
        self.target = target
    }

    // MARK: - ListBaseInfo

    public func baseListViewController() -> UIViewController? {
        target?.baseListViewController()
    }

    public func cellSizeCached() -> Bool {
        target?.cellSizeCached() ?? false
    }

    public func listUserInfo() -> [String: Any]? {
        target?.listUserInfo()
    }

    public func sectionViewModelFromData(_ data: Any) -> BaseListSectionViewModel? {
        target?.sectionViewModelFromData(data)
    }

    public func sectionController(forSection section: Int) -> BaseListSectionController? {
        target?.sectionController(forSection: section)
    }

    public func sectionController(forSectionViewModel sectionViewModel: BaseListSectionViewModel) -> BaseListSectionController? {
        target?.sectionController(forSectionViewModel: sectionViewModel)
    }

    public func addDisposableRequestInfo(_ requestInfo: [String: Any]) {
        target?.addDisposableRequestInfo(requestInfo)
    }

    public func listViewModel() -> BaseListViewModel? {
        target?.listViewModel()
    }

    public func registerListObserver(_ observer: AnyObject) {
        target?.registerListObserver(observer)
    }

    public func removeListObserver(_ observer: AnyObject) {
        target?.removeListObserver(observer)
    }

    public func responderForProtocol<T>(_ protocolType: T.Type) -> T? {
        target?.responderForProtocol(protocolType)
    }

    // MARK: - ListUIInfo

    public func scrollView() -> UIScrollView? {
        target?.scrollView()
    }

    public func visibleSectionControllers() -> [BaseListSectionController] {
        target?.visibleSectionControllers() ?? []
    }

    public func isRefreshing() -> Bool {
        target?.isRefreshing() ?? false
    }

    public func isLoadingMore() -> Bool {
        target?.isLoadingMore() ?? false
    }

    public func isScrolling() -> Bool {
        target?.isScrolling() ?? false
    }

    public func isVisible() -> Bool {
        target?.isVisible() ?? false
    }

    public func loadMoreEnabled() -> Bool {
        target?.loadMoreEnabled() ?? false
    }

    public func isViewLoaded() -> Bool {
        target?.isViewLoaded() ?? false
    }

    public func containerSize() -> CGSize {
        target?.containerSize() ?? .zero
    }

    public func containerView() -> UIView? {
        target?.containerView()
    }

    public func listContentOffset() -> CGPoint {
        target?.listContentOffset() ?? .zero
    }

    public func listContentInset() -> UIEdgeInsets {
        target?.listContentInset() ?? .zero
    }

    public func listContentSize() -> CGSize {
        target?.listContentSize() ?? .zero
    }

    public func rect(forSection section: Int) -> CGRect {
        target?.rect(forSection: section) ?? .zero
    }

    public func rect(forView view: UIView) -> CGRect {
        target?.rect(forView: view) ?? .zero
    }

    // MARK: - ListOperation

    public func cancelRequestIfNeeded() {
        target?.cancelRequestIfNeeded()
    }

    public func clearList() {
        target?.clearList()
    }

    public func updateListIfNeeded() {
        target?.updateListIfNeeded()
    }

    public func updateListWithDataSourceIfNeeded() {
        target?.updateListWithDataSourceIfNeeded()
    }

    public func updateListWithDataSourceIfNeeded(completion: (() -> Void)?) {
        target?.updateListWithDataSourceIfNeeded(completion: completion)
    }

    public func clearAllCellSizeCaches() {
        target?.clearAllCellSizeCaches()
    }

    public func triggerPullDownRefreshIfNeeded() {
        target?.triggerPullDownRefreshIfNeeded()
    }

    public func triggerPullDownRefreshIfNeeded(contextInfo: [String: Any]?) {
        target?.triggerPullDownRefreshIfNeeded(contextInfo: contextInfo)
    }

    public func triggerPullUpLoadMoreIfNeeded() {
        target?.triggerPullUpLoadMoreIfNeeded()
    }

    public func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel
    ) -> Bool {
        target?.replaceSectionViewModel(sectionViewModel, with: newSectionViewModel) ?? false
    }

    public func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel,
        animated: Bool,
        completion: ((Bool) -> Void)?
    ) -> Bool {
        target?.replaceSectionViewModel(sectionViewModel, with: newSectionViewModel, animated: animated, completion: completion) ?? false
    }

    public func scrollToTop(animated: Bool) {
        target?.scrollToTop(animated: animated)
    }

    public func scrollToSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        scrollPosition: UICollectionView.ScrollPosition,
        animated: Bool
    ) {
        target?.scrollToSectionViewModel(sectionViewModel, scrollPosition: scrollPosition, animated: animated)
    }

    public func scrollToContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        target?.scrollToContentOffset(contentOffset, animated: animated)
    }

    // MARK: - ListNotification

    public func registerObserver(
        _ observer: AnyObject,
        actionBlock: @escaping (_ object: Any?, _ userInfo: Any?) -> Void,
        name: ListMsgName
    ) {
        target?.registerObserver(observer, actionBlock: actionBlock, name: name)
    }

    public func removeObserver(_ observer: AnyObject, name: ListMsgName) {
        target?.removeObserver(observer, name: name)
    }

    public func postMsgName(_ name: ListMsgName, object: Any?) {
        target?.postMsgName(name, object: object)
    }

    public func postMsgName(_ name: ListMsgName, object: Any?, userInfo: [String: Any]?) {
        target?.postMsgName(name, object: object, userInfo: userInfo)
    }
}
