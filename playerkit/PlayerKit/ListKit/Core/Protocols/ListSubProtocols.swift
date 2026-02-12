import UIKit

public typealias ListMsgName = String

/// 列表基础信息协议
/// - 实现者: ListContext
/// - 职责: 提供列表的基础能力，包括 ViewController 引用、Section 查询、观察者管理等
@MainActor
public protocol ListBaseInfo: AnyObject {

    /// 获取关联的 ViewController
    func baseListViewController() -> UIViewController?

    /// 是否启用 Cell 尺寸缓存
    func cellSizeCached() -> Bool

    /// 获取列表自定义信息
    func listUserInfo() -> [String: Any]?

    /// 根据数据创建 SectionViewModel（工厂模式）
    func sectionViewModelFromData(_ data: Any) -> BaseListSectionViewModel?

    /// 根据 Section 索引获取 SectionController
    func sectionController(forSection section: Int) -> BaseListSectionController?

    /// 根据 SectionViewModel 获取 SectionController
    func sectionController(forSectionViewModel sectionViewModel: BaseListSectionViewModel) -> BaseListSectionController?

    /// 添加可取消的请求信息（用于页面销毁时取消请求）
    func addDisposableRequestInfo(_ requestInfo: [String: Any])

    /// 获取 ListViewModel
    func listViewModel() -> BaseListViewModel?

    /// 注册列表观察者
    func registerListObserver(_ observer: AnyObject)

    /// 移除列表观察者
    func removeListObserver(_ observer: AnyObject)

    /// 根据协议类型查找对应的响应者（用于插件能力查询）
    func responderForProtocol<T>(_ protocolType: T.Type) -> T?
}

/// 列表 UI 信息协议
/// - 实现者: BaseListViewController
/// - 职责: 提供列表 UI 相关信息，包括滚动状态、可见区域、容器尺寸等
@MainActor
public protocol ListUIInfo: AnyObject {

    func scrollView() -> UIScrollView?

    func visibleSectionControllers() -> [BaseListSectionController]

    func isRefreshing() -> Bool

    func isLoadingMore() -> Bool

    func isScrolling() -> Bool

    func isVisible() -> Bool

    func loadMoreEnabled() -> Bool

    func isViewLoaded() -> Bool

    func containerSize() -> CGSize

    func containerView() -> UIView?

    func listContentOffset() -> CGPoint

    func listContentInset() -> UIEdgeInsets

    func listContentSize() -> CGSize

    func rect(forSection section: Int) -> CGRect

    func rect(forView view: UIView) -> CGRect
}

/// 列表操作协议
/// - 实现者: BaseListViewController
/// - 职责: 提供列表操作能力，包括刷新、加载更多、滚动、替换 Section 等
@MainActor
public protocol ListOperation: AnyObject {

    func cancelRequestIfNeeded()

    func clearList()

    func updateListIfNeeded()

    func updateListWithDataSourceIfNeeded()

    func updateListWithDataSourceIfNeeded(completion: (() -> Void)?)

    func clearAllCellSizeCaches()

    func triggerPullDownRefreshIfNeeded()

    func triggerPullDownRefreshIfNeeded(contextInfo: [String: Any]?)

    func triggerPullUpLoadMoreIfNeeded()

    func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel
    ) -> Bool

    func replaceSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        with newSectionViewModel: BaseListSectionViewModel,
        animated: Bool,
        completion: ((Bool) -> Void)?
    ) -> Bool

    func scrollToTop(animated: Bool)

    func scrollToSectionViewModel(
        _ sectionViewModel: BaseListSectionViewModel,
        scrollPosition: UICollectionView.ScrollPosition,
        animated: Bool
    )

    func scrollToContentOffset(_ contentOffset: CGPoint, animated: Bool)
}

/// 列表消息通知协议
/// - 实现者: BaseListViewController
/// - 职责: 提供组件间通信能力，支持观察者模式的消息订阅与发布
@MainActor
public protocol ListNotification: AnyObject {

    func registerObserver(
        _ observer: AnyObject,
        actionBlock: @escaping (_ object: Any?, _ userInfo: Any?) -> Void,
        name: ListMsgName
    )

    func removeObserver(_ observer: AnyObject, name: ListMsgName)

    func postMsgName(_ name: ListMsgName, object: Any?)

    func postMsgName(_ name: ListMsgName, object: Any?, userInfo: [String: Any]?)
}
