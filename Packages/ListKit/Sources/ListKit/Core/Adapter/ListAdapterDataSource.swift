import UIKit
import IGListKit

/// IGListKit 数据源桥接器
/// - 职责:
///   1. 实现 IGListKit.ListAdapterDataSource 协议
///   2. 提供 Section 数据给 IGListKit
///   3. 创建 SectionController
///   4. 分发 ViewController 生命周期给所有 SectionController
@MainActor
public final class ListKitAdapterDataSource: NSObject, IGListKit.ListAdapterDataSource {

    /// 外部数据源（BaseListViewController）
    public weak var dataSource: ListViewControllerDataSource?

    /// 关联的 ViewController
    private weak var viewController: UIViewController?

    /// 生命周期监听者列表（SectionController）
    private var lifeCycleListeners: [WeakRef<AnyObject>] = []

    public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    // MARK: - IGListKit.ListAdapterDataSource

    /// 返回列表数据（SectionViewModel 数组）
    public func objects(for listAdapter: IGListKit.ListAdapter) -> [any IGListKit.ListDiffable] {
        return dataSource?.sectionViewModels() ?? []
    }

    /// 根据 object 创建对应的 SectionController
    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerFor object: Any) -> IGListKit.ListSectionController {
        guard let sectionViewModel = object as? BaseListSectionViewModel else {
            return IGListKit.ListSectionController()
        }
        guard let scClass = type(of: sectionViewModel).sectionControllerClass() else {
            return IGListKit.ListSectionController()
        }
        let sectionController = scClass.init()

        // 设置布局更新权限检查闭包
        sectionController.canUpdateLayout = { [weak listAdapter, weak sectionController] in
            guard let adapter = listAdapter, let sc = sectionController else { return false }
            return adapter.section(for: sc) != NSNotFound
        }

        // 通知外部 SectionController 已创建
        dataSource?.dataSourceDidCreateSectionController(sectionController, forSectionViewModel: sectionViewModel)

        // 建立 SectionViewModel 与 SectionController 的关联
        sectionViewModel.sectionContext = sectionController

        // 注册生命周期监听
        addLifeCycleListener(sectionController)

        return sectionController
    }

    /// 返回空列表时显示的 View（暂未实现）
    public func emptyView(for listAdapter: IGListKit.ListAdapter) -> UIView? {
        return nil
    }

    // MARK: - LifeCycle Management

    /// 添加生命周期监听者
    func addLifeCycleListener(_ listener: ListControllerLifeCycle) {
        lifeCycleListeners.removeAll { $0.value == nil }
        lifeCycleListeners.append(WeakRef(value: listener as AnyObject))
    }

    /// 通知 VC 即将显示
    func notifyWillAppear(_ animated: Bool, isBeingPresented: Bool, isMovingToParent: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerWillAppear(animated, isBeingPresented: isBeingPresented, isMovingToParent: isMovingToParent)
        }
    }

    /// 通知 VC 已显示
    func notifyDidAppear(_ animated: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerDidAppear(animated)
        }
    }

    /// 通知 VC 即将消失
    func notifyWillDisappear(_ animated: Bool, isBeingDismissed: Bool, isMovingFromParent: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerWillDisappear(animated, isBeingDismissed: isBeingDismissed, isMovingFromParent: isMovingFromParent)
        }
    }

    /// 通知 VC 已消失
    func notifyDidDisappear(_ animated: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerDidDisappear(animated)
        }
    }

    /// 通知 App 进入后台
    func notifyAppDidEnterBackground() {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.appDidEnterBackground()
        }
    }

    /// 通知 App 即将进入前台
    func notifyAppWillEnterForeground() {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.appWillEnterForeground()
        }
    }
}

/// 弱引用包装器
private struct WeakRef<T: AnyObject> {
    weak var value: T?
}
