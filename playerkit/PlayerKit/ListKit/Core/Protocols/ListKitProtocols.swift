import UIKit
import IGListKit

// MARK: - Protocols

/// VC 的数据源协议，告诉列表有哪些 section
/// - 实现者: BaseListViewController
/// - 职责: 提供 sectionViewModels、workingRangeSize、Header 吸顶配置
@MainActor
public protocol ListViewControllerDataSource: AnyObject {
    /// 提供 section 数据
    func sectionViewModels() -> [BaseListSectionViewModel]
    /// 预加载范围
    func workingRangeSize() -> Int
    /// Header 是否吸顶
    func shouldStickHeader(atSectionIndex sectionIndex: Int, sectionController: BaseListSectionController) -> Bool
    /// SectionController 创建回调
    func dataSourceDidCreateSectionController(_ sectionController: BaseListSectionController, forSectionViewModel sectionViewModel: BaseListSectionViewModel)
}

public extension ListViewControllerDataSource {
    func workingRangeSize() -> Int { 0 }
    func shouldStickHeader(atSectionIndex sectionIndex: Int, sectionController: BaseListSectionController) -> Bool { false }
    func dataSourceDidCreateSectionController(_ sectionController: BaseListSectionController, forSectionViewModel sectionViewModel: BaseListSectionViewModel) {}
}

/// 监听列表更新事件
/// - 实现者: ListKitAdapterUpdaterDelegate (桥接)
/// - 职责: 监听 reloadData、performBatchUpdates 等列表更新事件
@MainActor
public protocol ListUpdateDelegate: AnyObject {
    /// 将要刷新
    func listWillReloadData(collectionView: UICollectionView)
    /// 刷新完成
    func listDidReloadData(collectionView: UICollectionView)
    /// 批量更新完成
    func listDidPerformBatchUpdates(collectionView: UICollectionView)
}

public extension ListUpdateDelegate {
    func listWillReloadData(collectionView: UICollectionView) {}
    func listDidReloadData(collectionView: UICollectionView) {}
    func listDidPerformBatchUpdates(collectionView: UICollectionView) {}
}

/// 监听 Section 的显示/隐藏
/// - 实现者: BaseListViewController
/// - 职责: 接收 Section 进入/离开屏幕的事件
@MainActor
public protocol ListDisplayDelegate: AnyObject {
    /// Section 将显示
    func listWillDisplaySectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int)
    /// Section 已移出屏幕
    func listDidEndDisplayingSectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int)
}

public extension ListDisplayDelegate {
    func listWillDisplaySectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int) {}
    func listDidEndDisplayingSectionViewModel(_ sectionViewModel: BaseListSectionViewModel, atIndex index: Int) {}
}

/// VC 生命周期 + App 前后台切换回调
/// - 实现者: BaseListSectionController
/// - 职责: 让 SectionController 能感知 VC 生命周期和 App 前后台切换
@MainActor
public protocol ListControllerLifeCycle: AnyObject {
    /// VC 即将显示
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - isBeingPresented: 是否正在被 present
    ///   - isMovingToParent: 是否正在移动到父 VC
    func viewControllerWillAppear(_ animated: Bool, isBeingPresented: Bool, isMovingToParent: Bool)
    /// VC 已显示
    func viewControllerDidAppear(_ animated: Bool)
    /// VC 即将消失
    /// - Parameters:
    ///   - animated: 是否动画
    ///   - isBeingDismissed: 是否正在被 dismiss
    ///   - isMovingFromParent: 是否正在从父 VC 移除
    func viewControllerWillDisappear(_ animated: Bool, isBeingDismissed: Bool, isMovingFromParent: Bool)
    /// VC 已消失
    func viewControllerDidDisappear(_ animated: Bool)
    /// 收到内存警告
    func viewControllerDidReceiveMemoryWarning()
    /// App 进入后台
    func appDidEnterBackground()
    /// App 即将进入前台
    func appWillEnterForeground()
    /// App 即将失去焦点
    func appWillResignActive()
    /// App 已获得焦点
    func appDidBecomeActive()
}

public extension ListControllerLifeCycle {
    func viewControllerWillAppear(_ animated: Bool, isBeingPresented: Bool, isMovingToParent: Bool) {}
    func viewControllerDidAppear(_ animated: Bool) {}
    func viewControllerWillDisappear(_ animated: Bool, isBeingDismissed: Bool, isMovingFromParent: Bool) {}
    func viewControllerDidDisappear(_ animated: Bool) {}
    func viewControllerDidReceiveMemoryWarning() {}
    func appDidEnterBackground() {}
    func appWillEnterForeground() {}
    func appWillResignActive() {}
    func appDidBecomeActive() {}
}

/// Section 级别的操作能力
/// - 实现者: BaseListSectionController
/// - 职责: 提供 Section 内部的刷新、更新、滚动等操作
@MainActor
public protocol ListSectionContext: AnyObject {
    /// 刷新单个 Section
    func reloadSection(animated: Bool, completion: ((Bool) -> Void)?)
    /// 更新单个 Section
    func updateSection(animated: Bool, completion: ((Bool) -> Void)?)
    /// 滚动到指定 item（Section 内部索引）
    func scrollToItem(atIndex index: Int, scrollPosition: UICollectionView.ScrollPosition, animated: Bool)
}

/// 容器级别的操作能力（比 SectionContext 范围更大）
/// - 实现者: BaseListViewController
/// - 职责: 提供整个列表的刷新、更新、滚动等操作
@MainActor
public protocol ListContainerContext: AnyObject {
    /// 刷新整个列表
    func reloadContainer(completion: ((Bool) -> Void)?)
    /// 更新整个列表
    func updateContainer(animated: Bool, completion: ((Bool) -> Void)?)
    /// 滚动到指定对象（通过对象引用定位，而非索引）
    func scrollToObject(_ object: AnyObject, supplementaryKinds: [String]?, scrollDirection: UICollectionView.ScrollDirection, scrollPosition: UICollectionView.ScrollPosition, animated: Bool)
    /// 获取可见的 sections
    func visibleSectionViewModels() -> [BaseListSectionViewModel]
}

/// 容器配置
/// - 实现者: BaseListViewController
/// - 职责: 提供列表容器的配置信息（如分隔线配置）
@MainActor
public protocol ListContainerConfig: AnyObject {
    /// 分隔线配置
    var separatorConfig: ListSeparatorConfig { get }
}

/// 数据状态管理协议
/// - 实现者: BaseListViewModel
/// - 职责: 管理数据源状态、刷新状态、加载更多状态
@MainActor
public protocol ListDataStateProtocol: AnyObject {
    /// 数据状态（无数据/空/有内容）
    var dataSourceState: ListDataSourceState { get }
    /// 是否有更多数据
    var dataSourceHasMore: Bool { get }
    /// 刷新状态
    var refreshState: ListDataLoadState { get set }
    /// 加载更多状态
    var loadMoreState: ListDataLoadState { get set }
}

/// 监听 SectionController 的显示状态
/// - 实现者: 业务层（可选）
/// - 职责: 监听 SectionController 进入/离开屏幕
@MainActor
public protocol ListSectionControllerDelegate: AnyObject {
    /// SectionController 将显示
    func sectionControllerWillDisplay(_ sectionController: BaseListSectionController)
    /// SectionController 已移出
    func sectionControllerDidEndDisplaying(_ sectionController: BaseListSectionController)
}

public extension ListSectionControllerDelegate {
    func sectionControllerWillDisplay(_ sectionController: BaseListSectionController) {}
    func sectionControllerDidEndDisplaying(_ sectionController: BaseListSectionController) {}
}

/// SectionController 级别的滚动事件
/// - 实现者: 业务层（可选）
/// - 职责: 监听 SectionController 内的滚动事件
@MainActor
public protocol ListSectionControllerScrollDelegate: AnyObject {
    /// 滚动中（高频触发）
    func sectionControllerDidScroll(_ sectionController: BaseListSectionController)
    /// 开始拖拽
    func sectionControllerWillBeginDragging(_ sectionController: BaseListSectionController)
    /// 结束拖拽
    func sectionControllerDidEndDragging(_ sectionController: BaseListSectionController, willDecelerate: Bool)
    /// 减速结束
    func sectionControllerDidEndDecelerating(_ sectionController: BaseListSectionController)
}

public extension ListSectionControllerScrollDelegate {
    func sectionControllerDidScroll(_ sectionController: BaseListSectionController) {}
    func sectionControllerWillBeginDragging(_ sectionController: BaseListSectionController) {}
    func sectionControllerDidEndDragging(_ sectionController: BaseListSectionController, willDecelerate: Bool) {}
    func sectionControllerDidEndDecelerating(_ sectionController: BaseListSectionController) {}
}

/// 预加载机制（提前准备屏幕外的数据/资源）
/// - 实现者: 业务层（可选）
/// - 职责: 监听 SectionController 进入/离开预加载范围，用于预加载图片、视频等资源
@MainActor
public protocol ListSectionControllerWorkingRangeDelegate: AnyObject {
    /// 进入预加载范围
    func sectionControllerWillEnterWorkingRange(_ sectionController: BaseListSectionController)
    /// 离开预加载范围
    func sectionControllerDidExitWorkingRange(_ sectionController: BaseListSectionController)
}

public extension ListSectionControllerWorkingRangeDelegate {
    func sectionControllerWillEnterWorkingRange(_ sectionController: BaseListSectionController) {}
    func sectionControllerDidExitWorkingRange(_ sectionController: BaseListSectionController) {}
}
