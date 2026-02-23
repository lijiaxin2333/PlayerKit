import UIKit
import PlayerKit

@MainActor
final class LoopingDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示循环播放与重播功能：支持开启/关闭循环模式，播放完成后自动重播，以及手动触发重播。"
    }

    override var demoPlugins: [String] {
        ["PlayerLoopingPlugin", "PlayerReplayPlugin", "PlayerFinishViewPlugin", "PlayerPlaybackControlPlugin"]
    }

    private let statusLabel = UILabel()

    override func onPlayerReady() {
        statusLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .semibold)
        statusLabel.textColor = .label
        statusLabel.numberOfLines = 0
        updateStatus()
        controlStack.addArrangedSubview(statusLabel)

        let row1 = makeHStack()
        row1.addArrangedSubview(makeActionButton(title: "切换循环", action: #selector(toggleLoop)))
        row1.addArrangedSubview(makeActionButton(title: "重播", action: #selector(replay)))
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "播放/暂停", action: #selector(togglePlay)))
        row2.addArrangedSubview(makeActionButton(title: "显示完成视图", action: #selector(showFinish)))
        controlStack.addArrangedSubview(row2)

        player.context.add(self, event: .playerLoopingDidChange, option: .none) { [weak self] _, _ in
            self?.updateStatus()
        }
        player.context.add(self, event: .playerPlaybackDidFinish, option: .none) { [weak self] _, _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let looping = player.context.resolveService(PlayerLoopingService.self)
        let replay = player.context.resolveService(PlayerReplayService.self)
        statusLabel.text = "循环模式: \(looping?.isLooping == true ? "开启" : "关闭")\n重播次数: \(replay?.replayCount ?? 0)"
    }

    @objc private func toggleLoop() {
        player.context.resolveService(PlayerLoopingService.self)?.toggleLooping()
    }

    @objc private func replay() {
        player.context.resolveService(PlayerReplayService.self)?.replay()
        updateStatus()
    }

    @objc private func togglePlay() {
        player.context.resolveService(PlayerPlaybackControlService.self)?.togglePlayPause()
    }

    @objc private func showFinish() {
        player.context.resolveService(PlayerFinishViewService.self)?.showFinishView()
    }
}
