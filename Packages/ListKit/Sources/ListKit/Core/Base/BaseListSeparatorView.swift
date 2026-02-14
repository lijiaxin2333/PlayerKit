import UIKit

// MARK: - BaseListSeparatorView

@MainActor
public final class BaseListSeparatorView: UICollectionReusableView {

    private let lineView = UIView()

    public var separatorInsets: ListSeparatorInsets = ListSeparatorInsets() {
        didSet { setNeedsLayout() }
    }

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
