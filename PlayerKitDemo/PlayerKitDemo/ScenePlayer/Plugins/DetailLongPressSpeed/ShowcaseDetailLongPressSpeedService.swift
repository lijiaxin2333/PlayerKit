import UIKit
import BizPlayerKit

@MainActor
public protocol ShowcaseDetailLongPressSpeedService: PluginService {
    var isLongPressSpeedActive: Bool { get }
    func beginLongPressSpeed()
    func endLongPressSpeed()
}
