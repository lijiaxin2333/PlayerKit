import UIKit
import IGListKit

@MainActor
public final class ListKitAdapterDataSource: NSObject, IGListKit.ListAdapterDataSource {

    public weak var dataSource: ListViewControllerDataSource?
    private weak var viewController: UIViewController?
    private var lifeCycleListeners: [WeakRef<AnyObject>] = []

    public init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()
    }

    public func objects(for listAdapter: IGListKit.ListAdapter) -> [any IGListKit.ListDiffable] {
        return dataSource?.sectionViewModels() ?? []
    }

    public func listAdapter(_ listAdapter: IGListKit.ListAdapter, sectionControllerFor object: Any) -> IGListKit.ListSectionController {
        guard let sectionViewModel = object as? BaseListSectionViewModel else {
            return IGListKit.ListSectionController()
        }
        guard let scClass = type(of: sectionViewModel).sectionControllerClass() else {
            return IGListKit.ListSectionController()
        }
        let sectionController = scClass.init()

        sectionController.canUpdateLayout = { [weak listAdapter, weak sectionController] in
            guard let adapter = listAdapter, let sc = sectionController else { return false }
            return adapter.section(for: sc) != NSNotFound
        }

        dataSource?.dataSourceDidCreateSectionController(sectionController, forSectionViewModel: sectionViewModel)
        sectionViewModel.sectionContext = sectionController
        addLifeCycleListener(sectionController)

        return sectionController
    }

    public func emptyView(for listAdapter: IGListKit.ListAdapter) -> UIView? {
        return nil
    }

    func addLifeCycleListener(_ listener: ListControllerLifeCycle) {
        lifeCycleListeners.removeAll { $0.value == nil }
        lifeCycleListeners.append(WeakRef(value: listener as AnyObject))
    }

    func notifyWillAppear(_ animated: Bool, isBeingPresented: Bool, isMovingToParent: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerWillAppear(animated, isBeingPresented: isBeingPresented, isMovingToParent: isMovingToParent)
        }
    }

    func notifyDidAppear(_ animated: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerDidAppear(animated)
        }
    }

    func notifyWillDisappear(_ animated: Bool, isBeingDismissed: Bool, isMovingFromParent: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerWillDisappear(animated, isBeingDismissed: isBeingDismissed, isMovingFromParent: isMovingFromParent)
        }
    }

    func notifyDidDisappear(_ animated: Bool) {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.viewControllerDidDisappear(animated)
        }
    }

    func notifyAppDidEnterBackground() {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.appDidEnterBackground()
        }
    }

    func notifyAppWillEnterForeground() {
        for ref in lifeCycleListeners {
            (ref.value as? ListControllerLifeCycle)?.appWillEnterForeground()
        }
    }
}

private struct WeakRef<T: AnyObject> {
    weak var value: T?
}
