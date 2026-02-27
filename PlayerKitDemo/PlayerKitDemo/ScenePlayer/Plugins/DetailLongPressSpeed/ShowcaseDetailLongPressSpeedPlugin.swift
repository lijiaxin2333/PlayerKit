import UIKit
import BizPlayerKit

@MainActor
public final class ShowcaseDetailLongPressSpeedPlugin: BasePlugin, ShowcaseDetailLongPressSpeedService {

    private(set) public var isLongPressSpeedActive: Bool = false
    private var savedSpeed: Float = 1.0
    private let longPressSpeed: Float = 3.0

    @PlayerPlugin private var speedService: PlayerSpeedService?

    public func beginLongPressSpeed() {
        guard !isLongPressSpeedActive else { return }
        guard let speedService = speedService else { return }
        savedSpeed = speedService.currentSpeed
        speedService.setSpeed(longPressSpeed)
        isLongPressSpeedActive = true
    }

    public func endLongPressSpeed() {
        guard isLongPressSpeedActive else { return }
        guard let speedService = speedService else { return }
        speedService.setSpeed(savedSpeed)
        isLongPressSpeedActive = false
    }

    public override func pluginWillUnload(_ context: ContextProtocol) {
        if isLongPressSpeedActive {
            endLongPressSpeed()
        }
        super.pluginWillUnload(context)
    }
}
