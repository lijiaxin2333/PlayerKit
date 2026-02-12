import Foundation
import UIKit

@MainActor
public protocol PlayerSpeedPanelService: CCLCompService {
    var isShowing: Bool { get }
    func dismissPanel(animated: Bool)
}
