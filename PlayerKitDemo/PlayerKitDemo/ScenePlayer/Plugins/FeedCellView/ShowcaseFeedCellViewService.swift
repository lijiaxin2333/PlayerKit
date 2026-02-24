import UIKit
import PlayerKit

@MainActor
public class ShowcaseFeedCellViewConfigModel {
    public weak var contentView: UIView?
    public weak var playerContainer: UIView?

    public init(contentView: UIView, playerContainer: UIView) {
        self.contentView = contentView
        self.playerContainer = playerContainer
    }
}

@MainActor
public protocol ShowcaseFeedCellViewService: PluginService {
    var playerContainerView: UIView? { get }
    var contentView: UIView? { get }
}
