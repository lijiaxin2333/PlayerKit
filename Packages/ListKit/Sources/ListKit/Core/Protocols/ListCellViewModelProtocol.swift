import UIKit

/// CellViewModel 协议，定义 Cell 级别 ViewModel 的接口规范
/// - 实现者: 业务层 CellViewModel
/// - 职责:
///   1. 提供 Cell 类型和尺寸
///   2. 管理可见性状态
///   3. 响应 Cell 显示/隐藏事件
///   4. 响应 VC 生命周期事件
@MainActor
public protocol ListCellViewModelProtocol: AnyObject {

    /// 返回 Cell 的类型
    func cellClass() -> AnyClass

    /// 返回 Cell 的尺寸
    func cellSize() -> CGSize

    /// 返回 Cell 的期望尺寸（用于自适应布局）
    func preferredCellSize() -> CGSize

    /// Cell 是否可见
    var isVisible: Bool { get set }

    /// CellViewModel 即将显示
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func cellViewModelWillDisplay(duplicateReload: Bool)

    /// CellViewModel 已移出屏幕
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func cellViewModelDidEndDisplaying(duplicateReload: Bool)

    /// VC viewWillAppear 时触发
    func cellViewModelWillAppearByViewController()

    /// VC viewDidAppear 时触发
    func cellViewModelDidAppearByViewController()

    /// VC viewWillDisappear 时触发
    func cellViewModelWillDisappearByViewController()

    /// VC viewDidDisappear 时触发
    func cellViewModelDidDisappearByViewController()

    /// 所属 SectionViewModel 即将显示时触发
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func sectionViewModelWillDisplay(duplicateReload: Bool)

    /// 所属 SectionViewModel 已移出屏幕时触发
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func sectionViewModelDidEndDisplaying(duplicateReload: Bool)
}

public extension ListCellViewModelProtocol {

    func cellViewModelWillDisplay(duplicateReload: Bool) {}

    func cellViewModelDidEndDisplaying(duplicateReload: Bool) {}

    func cellViewModelWillAppearByViewController() {}

    func cellViewModelDidAppearByViewController() {}

    func cellViewModelWillDisappearByViewController() {}

    func cellViewModelDidDisappearByViewController() {}

    func sectionViewModelWillDisplay(duplicateReload: Bool) {}

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool) {}
}
