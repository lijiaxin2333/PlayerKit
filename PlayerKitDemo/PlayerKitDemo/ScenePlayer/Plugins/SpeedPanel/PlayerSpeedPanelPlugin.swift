import Foundation
import UIKit
import PlayerKit

@MainActor
public final class PlayerSpeedPanelPlugin: BasePlugin, PlayerSpeedPanelService {

    @PlayerPlugin private var speedService: PlayerSpeedService?
    @PlayerPlugin private var gestureService: PlayerGestureService?

    private var panelView: PlayerSpeedPanelView?

    public private(set) var isShowing: Bool = false

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        context.add(self, event: .playerGestureLongPress) { [weak self] obj, _ in
            guard let stateRaw = obj as? Int,
                  stateRaw == UIGestureRecognizer.State.began.rawValue else { return }
            self?.handleLongPress()
        }

        context.add(self, event: .playerSpeedDidChange) { [weak self] obj, _ in
            guard let self = self, let speed = obj as? Float else { return }
            self.panelView?.updateSelection(currentSpeed: speed)
        }
    }

    private func handleLongPress() {
        guard !isShowing else { return }
        guard let host = gestureService?.gestureView?.window?.rootViewController?.view else { return }
        showPanel(on: host)
    }

    private func showPanel(on view: UIView) {
        isShowing = true

        let panel = PlayerSpeedPanelView(frame: view.bounds)
        panel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(panel)
        self.panelView = panel

        panel.updateSelection(currentSpeed: speedService?.currentSpeed ?? 1.0)

        panel.onSelectSpeed = { [weak self] rate in
            self?.speedService?.setSpeed(rate)
        }

        panel.onDismiss = { [weak self] in
            self?.dismissPanel(animated: true)
        }

        panel.showAnimated()

        context?.post(.playerSpeedPanelDidShow, sender: self)
    }

    public func dismissPanel(animated: Bool) {
        guard isShowing else { return }
        isShowing = false

        if animated {
            panelView?.dismissAnimated { [weak self] in
                self?.panelView = nil
            }
        } else {
            panelView?.removeFromSuperview()
            panelView = nil
        }

        context?.post(.playerSpeedPanelDidDismiss, sender: self)
    }
}
