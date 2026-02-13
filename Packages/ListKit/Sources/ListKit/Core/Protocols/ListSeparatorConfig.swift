import UIKit

@MainActor
public final class ListSeparatorConfig {
    public var displayState: ListSeparatorDisplayState = .hideLastOnly
    public var height: CGFloat = 0.5
    public var separatorInsets: ListSeparatorInsets = ListSeparatorInsets(left: 10, right: 10)
    public var separatorColor: UIColor = UIColor(white: 1, alpha: 0.1)

    public init() {}
}
