import UIKit

/// SectionViewModel 协议，定义 Section 级别 ViewModel 的接口规范
/// - 实现者: 业务层 SectionViewModel
/// - 职责:
///   1. 声明能处理的数据类型
///   2. 根据数据创建 SectionViewModel
///   3. 响应 Section 显示/隐藏事件
///   4. 响应 VC 生命周期事件
@MainActor
public protocol ListSectionViewModelProtocol: AnyObject {

    /// 判断是否能处理指定类型的数据
    /// - Parameter data: 原始数据
    /// - Returns: 是否能处理
    static func canHandleData(_ data: Any?) -> Bool

    /// 根据数据创建 SectionViewModel
    /// - Parameters:
    ///   - data: 原始数据
    ///   - context: 列表上下文
    /// - Returns: 创建的 SectionViewModel
    static func sectionViewModel(forData data: Any, context: ListContext) -> Self

    /// SectionViewModel 即将显示
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func sectionViewModelWillDisplay(duplicateReload: Bool)

    /// SectionViewModel 已移出屏幕
    /// - Parameter duplicateReload: 是否是重复刷新触发的
    func sectionViewModelDidEndDisplaying(duplicateReload: Bool)

    /// VC viewWillAppear 时触发
    func sectionViewModelWillAppearByViewController()

    /// VC viewDidAppear 时触发
    func sectionViewModelDidAppearByViewController()

    /// VC viewWillDisappear 时触发
    func sectionViewModelWillDisappearByViewController()

    /// VC viewDidDisappear 时触发
    func sectionViewModelDidDisappearByViewController()
}

public extension ListSectionViewModelProtocol {

    func sectionViewModelWillDisplay(duplicateReload: Bool) {}

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool) {}

    func sectionViewModelWillAppearByViewController() {}

    func sectionViewModelDidAppearByViewController() {}

    func sectionViewModelWillDisappearByViewController() {}

    func sectionViewModelDidDisappearByViewController() {}
}
