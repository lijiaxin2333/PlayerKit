import UIKit

/// Cell 协议，定义 UICollectionViewCell 的接口规范
/// - 实现者: 业务层 Cell
/// - 职责:
///   1. 绑定 CellViewModel
///   2. 响应 Cell 显示/隐藏事件
///   3. 响应 VC 生命周期事件
@MainActor
public protocol ListCellProtocol: AnyObject {

    /// 绑定 CellViewModel（Cell 创建或复用时调用）
    func bindCellViewModel(_ cellViewModel: ListCellViewModelProtocol)

    /// 获取当前绑定的 CellViewModel
    func cellViewModel() -> ListCellViewModelProtocol?

    /// Cell 即将显示
    /// - Parameter duplicateReload: 是否是重复刷新触发的（如 reloadData 导致已可见的 Cell 再次触发）
    func cellWillDisplay(duplicateReload: Bool)

    /// Cell 已移出屏幕
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func cellDidEndDisplaying(duplicateReload: Bool)

    /// VC viewWillAppear 时触发
    func cellWillAppearByViewController()

    /// VC viewDidAppear 时触发
    func cellDidAppearByViewController()

    /// VC viewWillDisappear 时触发
    func cellWillDisappearByViewController()

    /// VC viewDidDisappear 时触发
    func cellDidDisappearByViewController()
}



// MARK: Protocol default Implementation
public extension ListCellProtocol {

    func cellWillDisplay(duplicateReload: Bool) {}

    func cellDidEndDisplaying(duplicateReload: Bool) {}

    func cellWillAppearByViewController() {}

    func cellDidAppearByViewController() {}

    func cellWillDisappearByViewController() {}

    func cellDidDisappearByViewController() {}
}
