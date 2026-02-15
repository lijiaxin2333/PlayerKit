import UIKit

/// 列表滚动事件协议
/// - 实现者: BaseListViewController
/// - 职责: 定义列表滚动相关的回调接口
@MainActor
public protocol ListScrollViewDelegate: AnyObject {

    /// 滚动中（高频触发）
    func scrollViewDidScroll(_ scrollView: UIScrollView)

    /// 开始拖拽
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)

    /// 即将结束拖拽
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>)

    /// 结束拖拽
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)

    /// 开始减速
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView)

    /// 减速结束
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)

    /// 滚动动画结束
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)

    /// 是否允许滚动到顶部
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool

    /// 滚动到顶部
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView)

    /// adjustedContentInset 变化
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView)
}

public extension ListScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {}
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {}
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {}
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool { true }
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {}
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {}
}

/// IGListKit 滚动事件桥接器
/// - 职责: 将 IGListKit 的滚动事件转发给内部代理和外部代理
/// - 内部代理: BaseListViewController（用于状态追踪和 Plugin 通知）
/// - 外部代理: 业务层注入的 scrollViewDelegate（可选）
@MainActor
final class ListKitAdapterScrollViewDelegate: NSObject, UIScrollViewDelegate {

    /// 内部代理（BaseListViewController）
    weak var delegate: ListScrollViewDelegate?

    /// 外部代理（业务层注入）
    weak var externalDelegate: UIScrollViewDelegate?

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView)
        externalDelegate?.scrollViewDidScroll?(scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDragging(scrollView)
        externalDelegate?.scrollViewWillBeginDragging?(scrollView)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        delegate?.scrollViewWillEndDragging(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        externalDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
        externalDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewWillBeginDecelerating(scrollView)
        externalDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndDecelerating(scrollView)
        externalDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidEndScrollingAnimation(scrollView)
        externalDelegate?.scrollViewDidEndScrollingAnimation?(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let result = externalDelegate?.scrollViewShouldScrollToTop?(scrollView) {
            return result
        }
        return delegate?.scrollViewShouldScrollToTop(scrollView) ?? true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScrollToTop(scrollView)
        externalDelegate?.scrollViewDidScrollToTop?(scrollView)
    }

    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidChangeAdjustedContentInset(scrollView)
        externalDelegate?.scrollViewDidChangeAdjustedContentInset?(scrollView)
    }
}
