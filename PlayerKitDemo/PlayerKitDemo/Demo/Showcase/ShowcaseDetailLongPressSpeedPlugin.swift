import UIKit
import PlayerKit

@MainActor
protocol ShowcaseDetailLongPressSpeedService: PluginService {
    var isLongPressSpeedActive: Bool { get }
    func beginLongPressSpeed()
    func endLongPressSpeed()
}

@MainActor
final class ShowcaseDetailLongPressSpeedPlugin: BasePlugin, ShowcaseDetailLongPressSpeedService {

    private(set) var isLongPressSpeedActive: Bool = false
    private var savedSpeed: Float = 1.0
    private let longPressSpeed: Float = 3.0

    @PlayerPlugin private var speedService: PlayerSpeedService?

    func beginLongPressSpeed() {
        guard !isLongPressSpeedActive else { return }
        guard let speedService = speedService else { return }
        savedSpeed = speedService.currentSpeed
        speedService.setSpeed(longPressSpeed)
        isLongPressSpeedActive = true
    }

    func endLongPressSpeed() {
        guard isLongPressSpeedActive else { return }
        guard let speedService = speedService else { return }
        speedService.setSpeed(savedSpeed)
        isLongPressSpeedActive = false
    }

    override func pluginWillUnload(_ context: ContextProtocol) {
        if isLongPressSpeedActive {
            endLongPressSpeed()
        }
        super.pluginWillUnload(context)
    }
}
