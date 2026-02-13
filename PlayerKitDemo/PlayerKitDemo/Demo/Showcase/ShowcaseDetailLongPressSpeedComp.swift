import UIKit
import PlayerKit

@MainActor
protocol ShowcaseDetailLongPressSpeedService: CCLCompService {
    var isLongPressSpeedActive: Bool { get }
    func beginLongPressSpeed()
    func endLongPressSpeed()
}

@MainActor
final class ShowcaseDetailLongPressSpeedComp: CCLBaseComp, ShowcaseDetailLongPressSpeedService {

    private(set) var isLongPressSpeedActive: Bool = false
    private var savedSpeed: Float = 1.0
    private let longPressSpeed: Float = 3.0

    func beginLongPressSpeed() {
        guard !isLongPressSpeedActive else { return }
        guard let speedService = context?.resolveService(PlayerSpeedService.self) else { return }
        savedSpeed = speedService.currentSpeed
        speedService.setSpeed(longPressSpeed)
        isLongPressSpeedActive = true
    }

    func endLongPressSpeed() {
        guard isLongPressSpeedActive else { return }
        guard let speedService = context?.resolveService(PlayerSpeedService.self) else { return }
        speedService.setSpeed(savedSpeed)
        isLongPressSpeedActive = false
    }

    override func componentWillUnload(_ context: CCLContextProtocol) {
        if isLongPressSpeedActive {
            endLongPressSpeed()
        }
        super.componentWillUnload(context)
    }
}
