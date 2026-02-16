import Foundation
import UIKit

@MainActor
public protocol PlayerSpeedPanelService: PluginService {
    var isShowing: Bool { get }
    func dismissPanel(animated: Bool)
}
