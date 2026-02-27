import UIKit

// MARK: - BaseListSeparatorView

/// 列表分隔线视图
/// 作为 Section Footer 显示，用于分隔不同 Section
@MainActor
public final class BaseListSeparatorView: UICollectionReusableView {

    /// 分隔线视图
    private let lineView = UIView()

    /// 分隔线左右边距
    public var separatorInsets: ListSeparatorInsets = ListSeparatorInsets() {
        didSet { setNeedsLayout() }
    }

    /// 分隔线颜色
    public var separatorColor: UIColor = UIColor(white: 1, alpha: 0.1) {
        didSet { lineView.backgroundColor = separatorColor }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        lineView.backgroundColor = separatorColor
        addSubview(lineView)
    }

    public required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        lineView.frame = CGRect(
            x: separatorInsets.left,
            y: 0,
            width: bounds.width - separatorInsets.left - separatorInsets.right,
            height: bounds.height
        )
    }
}
