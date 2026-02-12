import UIKit

// MARK: - Typealias

/// 配置 UICollectionView 的闭包
public typealias ListSetupBlock = (UICollectionView) -> Void

/// 列表更新完成后的回调，参数表示是否成功
public typealias ListUpdaterCompletion = (Bool) -> Void

/// 数据拉取完成的回调
public typealias ListFetchDataCompletion = () -> Void

/// 加载更多完成的回调
public typealias ListLoadMoreDataCompletion = () -> Void

// MARK: - Enums

/// 列表 diff 时的比较策略
public enum ListDiffOption {
    /// 指针比较（同一对象才算相同）
    case pointerPersonality
    /// 值比较（isEqual 判断）
    case equality
}

/// 数据源状态
public enum ListDataSourceState: Int {
    /// 无数据
    case none
    /// 空状态
    case empty
    /// 有内容
    case hasContent
}

/// 数据加载状态（用于下拉刷新/上拉加载）
public enum ListDataLoadState: Int {
    /// 未加载
    case isNotLoading
    /// 加载中
    case isLoading
    /// 加载失败
    case errored
    /// 已取消
    case cancelled
}

/// 分隔线左右边距
public struct ListSeparatorInsets: Equatable {
    public var left: CGFloat
    public var right: CGFloat

    public init(left: CGFloat = 10, right: CGFloat = 10) {
        self.left = left
        self.right = right
    }
}

/// 分隔线显示策略
public enum ListSeparatorDisplayState {
    /// 全部隐藏
    case hideAll
    /// 只隐藏最后一个
    case hideLastOnly
    /// 全部显示
    case showAll
}
