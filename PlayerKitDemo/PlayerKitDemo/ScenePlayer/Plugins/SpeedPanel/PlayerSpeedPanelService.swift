import Foundation
import UIKit
import PlayerKit

// MARK: - Speed Panel Events

public extension Event {
    /// 倍速面板显示
    static let playerSpeedPanelDidShow: Event = "PlayerSpeedPanelDidShow"
    /// 倍速面板关闭
    static let playerSpeedPanelDidDismiss: Event = "PlayerSpeedPanelDidDismiss"
}

// MARK: - Speed Panel Service Protocol

@MainActor
public protocol PlayerSpeedPanelService: PluginService {
    var isShowing: Bool { get }
    func dismissPanel(animated: Bool)
}
