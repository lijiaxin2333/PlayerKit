import UIKit

/// 分隔线配置
/// 用于配置列表分隔线的显示样式
@MainActor
public final class ListSeparatorConfig {

    /// 分隔线显示策略
    public var displayState: ListSeparatorDisplayState = .hideLastOnly

    /// 分隔线高度
    public var height: CGFloat = 0.5

    /// 分隔线左右边距
    public var separatorInsets: ListSeparatorInsets = ListSeparatorInsets(left: 10, right: 10)

    /// 分隔线颜色
    public var separatorColor: UIColor = UIColor(white: 1, alpha: 0.1)

    public init() {}
}
