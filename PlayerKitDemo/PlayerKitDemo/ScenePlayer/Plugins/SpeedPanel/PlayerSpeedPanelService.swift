import Foundation
import UIKit
import PlayerKit

@MainActor
public protocol PlayerSpeedPanelService: PluginService {
    var isShowing: Bool { get }
    func dismissPanel(animated: Bool)
}
