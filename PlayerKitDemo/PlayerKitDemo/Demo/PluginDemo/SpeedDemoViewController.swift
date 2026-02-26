import UIKit
import PlayerKit

@MainActor
final class SpeedDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示倍速播放功能：支持多种预设倍速切换、自定义倍速值设置，以及倍速面板的弹出交互。"
    }

    override var demoPlugins: [String] {
        ["PlayerSpeedPlugin", "PlayerSpeedPanelPlugin", "PlayerPlaybackControlPlugin"]
    }

    private let speedLabel = UILabel()
    private let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0]

    override func onPlayerReady() {
        speedLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        speedLabel.textColor = .label
        speedLabel.text = "当前倍速: 1.0x"
        controlStack.addArrangedSubview(speedLabel)

        let row1 = makeHStack()
        for speed in speeds {
            let btn = makeActionButton(title: "\(speed)x", action: #selector(speedTapped(_:)))
            btn.tag = Int(speed * 100)
            row1.addArrangedSubview(btn)
        }
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "恢复正常", action: #selector(resetSpeed)))
        row2.addArrangedSubview(makeActionButton(title: "播放/暂停", action: #selector(togglePlay)))
        controlStack.addArrangedSubview(row2)

        player.context.add(self, event: .playerSpeedDidChange, option: .none) { [weak self] object, _ in
            guard let self = self, let speed = object as? Float else { return }
            self.speedLabel.text = "当前倍速: \(speed)x"
        }
    }

    @objc private func speedTapped(_ sender: UIButton) {
        let speed = Float(sender.tag) / 100.0
        player.context.service(PlayerSpeedService.self)?.setSpeed(speed)
    }

    @objc private func resetSpeed() {
        player.context.service(PlayerSpeedService.self)?.setSpeed(1.0)
    }

    @objc private func togglePlay() {
        player.context.service(PlayerPlaybackControlService.self)?.togglePlayPause()
    }
}
