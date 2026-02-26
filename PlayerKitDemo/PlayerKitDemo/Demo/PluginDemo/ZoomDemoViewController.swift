import UIKit
import PlayerKit

@MainActor
final class ZoomDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示视频缩放功能：支持自由缩放、智能满屏（AspectFill）切换，以及手动设置缩放比例。"
    }

    override var demoPlugins: [String] {
        ["PlayerZoomPlugin", "PlayerGesturePlugin", "PlayerFullScreenPlugin"]
    }

    /// 场景层插件注册器
    override var sceneRegProvider: RegisterProvider? {
        ZoomDemoSceneRegProvider()
    }

    private let statusLabel = UILabel()

    override func onPlayerReady() {
        guard let gestureService = player.context.service(PlayerGestureService.self) else { return }
        gestureService.gestureView = playerContainer
        gestureService.isPinchEnabled = true  // 启用捏合缩放

        statusLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        updateStatus()
        controlStack.addArrangedSubview(statusLabel)

        let row1 = makeHStack()
        row1.addArrangedSubview(makeActionButton(title: "智能满屏", action: #selector(toggleAspectFill)))
        row1.addArrangedSubview(makeActionButton(title: "重置缩放", action: #selector(resetZoom)))
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "1.5x", action: #selector(zoom150)))
        row2.addArrangedSubview(makeActionButton(title: "2.0x", action: #selector(zoom200)))
        row2.addArrangedSubview(makeActionButton(title: "3.0x", action: #selector(zoom300)))
        controlStack.addArrangedSubview(row2)

        let row3 = makeHStack()
        row3.addArrangedSubview(makeActionButton(title: "全屏", action: #selector(toggleFullScreen)))
        controlStack.addArrangedSubview(row3)

        player.context.add(self, event: .playerZoomStateDidChanged, option: .none) { [weak self] _, _ in
            self?.updateStatus()
        }
        player.context.add(self, event: .playerAspectFillDidChanged, option: .none) { [weak self] _, _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let zoom = player.context.service(PlayerZoomService.self)
        let scale = zoom?.scale ?? 1.0
        let aspectFill = zoom?.isTurnOnAspectFill == true ? "开启" : "关闭"
        statusLabel.text = "缩放比例: \(String(format: "%.1f", scale))x | 智能满屏: \(aspectFill)"
    }

    @objc private func toggleAspectFill() {
        guard let zoom = player.context.service(PlayerZoomService.self) else { return }
        zoom.setAspectFillEnable(!zoom.isTurnOnAspectFill, animated: true)
        updateStatus()
    }

    @objc private func resetZoom() {
        player.context.service(PlayerZoomService.self)?.setScale(1.0)
        updateStatus()
    }

    @objc private func zoom150() {
        player.context.service(PlayerZoomService.self)?.setScale(1.5)
        updateStatus()
    }

    @objc private func zoom200() {
        player.context.service(PlayerZoomService.self)?.setScale(2.0)
        updateStatus()
    }

    @objc private func zoom300() {
        player.context.service(PlayerZoomService.self)?.setScale(3.0)
        updateStatus()
    }

    @objc private func toggleFullScreen() {
        player.context.service(PlayerFullScreenService.self)?.toggleFullScreen(orientation: .landscapeRight, animated: true)
    }
}

// MARK: - Scene RegProvider

@MainActor
private final class ZoomDemoSceneRegProvider: RegisterProvider {
    func registerPlugins(with registerSet: PluginRegisterSet) {
        // 场景层 UI 插件
        registerSet.addEntry(pluginClass: PlayerZoomPlugin.self,
                            serviceType: PlayerZoomService.self)
        registerSet.addEntry(pluginClass: PlayerGesturePlugin.self,
                            serviceType: PlayerGestureService.self)
        registerSet.addEntry(pluginClass: PlayerFullScreenPlugin.self,
                            serviceType: PlayerFullScreenService.self)
    }
}
