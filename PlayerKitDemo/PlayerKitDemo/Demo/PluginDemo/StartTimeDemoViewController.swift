import UIKit
import PlayerKit

@MainActor
final class StartTimeDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示起播时间与进度控制功能：支持设置视频起播时间点、Seek 跳转、进度拖拽，以及播放进度缓存与恢复。"
    }

    override var demoPlugins: [String] {
        ["PlayerStartTimePlugin", "PlayerProcessPlugin", "PlayerTimeControlPlugin", "PlayerPlaybackControlPlugin"]
    }

    private let statusLabel = UILabel()
    private let progressSlider = UISlider()

    override func onPlayerReady() {
        statusLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = "设置起播时间后重新加载视频生效"
        controlStack.addArrangedSubview(statusLabel)

        let row1 = makeHStack()
        row1.addArrangedSubview(makeActionButton(title: "起播 0s", action: #selector(startAt0)))
        row1.addArrangedSubview(makeActionButton(title: "起播 10s", action: #selector(startAt10)))
        row1.addArrangedSubview(makeActionButton(title: "起播 30s", action: #selector(startAt30)))
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "Seek 到 5s", action: #selector(seekTo5)))
        row2.addArrangedSubview(makeActionButton(title: "Seek 到 20s", action: #selector(seekTo20)))
        row2.addArrangedSubview(makeActionButton(title: "Seek 到 50%", action: #selector(seekToHalf)))
        controlStack.addArrangedSubview(row2)

        progressSlider.minimumTrackTintColor = .systemBlue
        progressSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderBegan(_:)), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        controlStack.addArrangedSubview(progressSlider)

        let row3 = makeHStack()
        row3.addArrangedSubview(makeActionButton(title: "缓存进度", action: #selector(cacheProgress)))
        row3.addArrangedSubview(makeActionButton(title: "恢复进度", action: #selector(restoreProgress)))
        controlStack.addArrangedSubview(row3)

        player.context.add(self, event: .playerTimeDidChange, option: .none) { [weak self] _, _ in
            self?.updateProgress()
        }
    }

    private func updateProgress() {
        let process = player.processService
        guard let process = process, !process.isScrubbing else { return }
        progressSlider.value = Float(process.progress)
        statusLabel.text = "当前: \(player.timeControlService?.currentTimeString(style: .standard) ?? "--") / \(player.timeControlService?.durationString(style: .standard) ?? "--")\n起播时间: \(String(format: "%.1f", player.startTimeService?.startTime ?? 0))s"
    }

    @objc private func startAt0() {
        player.startTimeService?.setStartTime(0)
        updateProgress()
    }

    @objc private func startAt10() {
        player.startTimeService?.setStartTime(10)
        updateProgress()
    }

    @objc private func startAt30() {
        player.startTimeService?.setStartTime(30)
        updateProgress()
    }

    @objc private func seekTo5() {
        player.processService?.seek(to: 5.0 / max(player.processService?.duration ?? 1, 1), completion: nil)
    }

    @objc private func seekTo20() {
        player.processService?.seek(to: 20.0 / max(player.processService?.duration ?? 1, 1), completion: nil)
    }

    @objc private func seekToHalf() {
        player.processService?.seek(to: 0.5, completion: nil)
    }

    @objc private func sliderBegan(_ slider: UISlider) {
        player.processService?.beginScrubbing()
    }

    @objc private func sliderChanged(_ slider: UISlider) {
        player.processService?.scrubbing(to: Double(slider.value))
    }

    @objc private func sliderEnded(_ slider: UISlider) {
        player.processService?.endScrubbing()
    }

    @objc private func cacheProgress() {
        player.startTimeService?.cacheCurrentProgress()
        player.toastService?.showToast("进度已缓存", style: .info, duration: 1.5)
    }

    @objc private func restoreProgress() {
        let cached = player.startTimeService?.cachedProgress(forKey: player.dataService?.dataModel.vid ?? "default")
        if let cached = cached {
            player.processService?.seek(to: cached / max(player.processService?.duration ?? 1, 1), completion: nil)
            player.toastService?.showToast("已恢复到 \(String(format: "%.1f", cached))s", style: .info, duration: 1.5)
        }
    }
}
