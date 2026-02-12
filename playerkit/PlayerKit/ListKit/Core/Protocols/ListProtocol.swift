import UIKit

/// 列表核心事件协议
/// 用于接收列表的各种事件回调（Section/Cell 显示隐藏、VC 生命周期、滚动事件等）
/// 通常由 Plugin 实现，用于监听列表事件并做出响应
@MainActor
public protocol ListProtocol: AnyObject {

    // MARK: - Section 显示/隐藏

    /// SectionViewModel 即将显示
    /// - Parameters:
    ///   - sectionViewModel: 即将显示的 SectionViewModel
    ///   - index: Section 索引
    ///   - duplicateReload: 是否是重复刷新触发的（如 reloadData 导致已可见的 section 再次触发 willDisplay）
    func sectionViewModelWillDisplay(
        _ sectionViewModel: BaseListSectionViewModel,
        forIndex index: Int,
        duplicateReload: Bool
    )

    /// SectionViewModel 已移出屏幕
    /// - Parameters:
    ///   - sectionViewModel: 已移出的 SectionViewModel
    ///   - index: Section 索引
    ///   - duplicateReload: 是否是重复刷新触发的
    func sectionViewModelDidEndDisplaying(
        _ sectionViewModel: BaseListSectionViewModel,
        forIndex index: Int,
        duplicateReload: Bool
    )

    // MARK: - Cell 显示/隐藏

    /// Cell 即将显示
    /// - Parameters:
    ///   - cell: 即将显示的 Cell
    ///   - indexPath: Cell 的 indexPath
    ///   - cellViewModel: Cell 对应的 ViewModel
    ///   - sectionViewModel: Cell 所属的 SectionViewModel
    ///   - duplicateReload: 是否是重复刷新触发的
    func cellWillDisplay(
        _ cell: UICollectionViewCell,
        atIndexPath indexPath: IndexPath,
        cellViewModel: ListCellViewModelProtocol,
        sectionViewModel: BaseListSectionViewModel,
        duplicateReload: Bool
    )

    /// Cell 已移出屏幕
    /// - Parameters:
    ///   - cell: 已移出的 Cell
    ///   - indexPath: Cell 的 indexPath
    ///   - cellViewModel: Cell 对应的 ViewModel
    ///   - sectionViewModel: Cell 所属的 SectionViewModel
    ///   - duplicateReload: 是否是重复刷新触发的
    func cellDidEndDisplaying(
        _ cell: UICollectionViewCell,
        atIndexPath indexPath: IndexPath,
        cellViewModel: ListCellViewModelProtocol,
        sectionViewModel: BaseListSectionViewModel,
        duplicateReload: Bool
    )

    // MARK: - VC 生命周期

    /// VC viewDidLoad 时触发
    func viewDidLoad(byViewController viewController: UIViewController)

    /// VC viewWillAppear 时触发
    func viewWillAppear(byViewController viewController: UIViewController)

    /// VC viewDidAppear 时触发
    func viewDidAppear(byViewController viewController: UIViewController)

    /// VC viewWillDisappear 时触发
    func viewWillDisappear(byViewController viewController: UIViewController)

    /// VC viewDidDisappear 时触发
    func viewDidDisappear(byViewController viewController: UIViewController)

    // MARK: - 列表数据更新

    /// 列表即将刷新 SectionViewModels
    /// - Parameters:
    ///   - sectionViewModels: 新的 SectionViewModels
    ///   - preSectionViewModels: 旧的 SectionViewModels（首次加载时为 nil）
    func listWillReloadSectionViewModels(
        _ sectionViewModels: [BaseListSectionViewModel],
        preSectionViewModels: [BaseListSectionViewModel]?
    )

    /// 列表已刷新 SectionViewModels
    /// - Parameters:
    ///   - sectionViewModels: 新的 SectionViewModels
    ///   - preSectionViewModels: 旧的 SectionViewModels（首次加载时为 nil）
    func listDidReloadSectionViewModels(
        _ sectionViewModels: [BaseListSectionViewModel],
        preSectionViewModels: [BaseListSectionViewModel]?
    )

    // MARK: - 滚动事件

    /// 滚动中
    func scrollViewDidScroll(_ scrollView: UIScrollView)

    /// 拖拽即将结束（可用于实现分页吸附）
    /// - Parameters:
    ///   - scrollView: 滚动视图
    ///   - velocity: 拖拽速度
    ///   - targetContentOffset: 目标偏移量（可修改此值实现吸附效果）
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)

    /// 拖拽结束
    /// - Parameters:
    ///   - scrollView: 滚动视图
    ///   - decelerate: 是否会继续减速
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)

    /// 减速结束
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)

    /// 滚动结束（拖拽或减速结束后触发）
    func scrollViewDidEndScrolling()

    /// 滚动动画结束（如 scrollToItem 触发的动画）
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)

    // MARK: - 其他事件

    /// 列表尺寸变化（如旋转屏幕）
    /// - Parameters:
    ///   - oldSize: 旧尺寸
    ///   - newSize: 新尺寸
    func listSizeDidChanged(oldSize: CGSize, newSize: CGSize)

    /// SectionController 进入预加载范围
    func sectionControllerWillEnterWorkingRange(_ sectionController: BaseListSectionController)

    /// SectionController 离开预加载范围
    func sectionControllerDidExitWorkingRange(_ sectionController: BaseListSectionController)
}



// MARK: Protocol Default Implementation
public extension ListProtocol {

    func sectionViewModelWillDisplay(
        _ sectionViewModel: BaseListSectionViewModel,
        forIndex index: Int,
        duplicateReload: Bool
    ) {}

    func sectionViewModelDidEndDisplaying(
        _ sectionViewModel: BaseListSectionViewModel,
        forIndex index: Int,
        duplicateReload: Bool
    ) {}

    func cellWillDisplay(
        _ cell: UICollectionViewCell,
        atIndexPath indexPath: IndexPath,
        cellViewModel: ListCellViewModelProtocol,
        sectionViewModel: BaseListSectionViewModel,
        duplicateReload: Bool
    ) {}

    func cellDidEndDisplaying(
        _ cell: UICollectionViewCell,
        atIndexPath indexPath: IndexPath,
        cellViewModel: ListCellViewModelProtocol,
        sectionViewModel: BaseListSectionViewModel,
        duplicateReload: Bool
    ) {}

    func viewDidLoad(byViewController viewController: UIViewController) {}
    func viewWillAppear(byViewController viewController: UIViewController) {}
    func viewDidAppear(byViewController viewController: UIViewController) {}
    func viewWillDisappear(byViewController viewController: UIViewController) {}
    func viewDidDisappear(byViewController viewController: UIViewController) {}

    func listWillReloadSectionViewModels(
        _ sectionViewModels: [BaseListSectionViewModel],
        preSectionViewModels: [BaseListSectionViewModel]?
    ) {}

    func listDidReloadSectionViewModels(
        _ sectionViewModels: [BaseListSectionViewModel],
        preSectionViewModels: [BaseListSectionViewModel]?
    ) {}

    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndScrolling() {}
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
    func listSizeDidChanged(oldSize: CGSize, newSize: CGSize) {}
    func sectionControllerWillEnterWorkingRange(_ sectionController: BaseListSectionController) {}
    func sectionControllerDidExitWorkingRange(_ sectionController: BaseListSectionController) {}
}
