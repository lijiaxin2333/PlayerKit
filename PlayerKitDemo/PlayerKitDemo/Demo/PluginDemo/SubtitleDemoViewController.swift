import UIKit
import PlayerKit

@MainActor
final class SubtitleDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示字幕功能：支持加载外挂字幕、开启/关闭字幕显示、调整字幕字体大小和颜色。"
    }

    override var demoPlugins: [String] {
        ["PlayerSubtitlePlugin", "PlayerPlaybackControlPlugin"]
    }

    private let statusLabel = UILabel()

    override func onPlayerReady() {
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        updateStatus()
        controlStack.addArrangedSubview(statusLabel)

        let row1 = makeHStack()
        row1.addArrangedSubview(makeActionButton(title: "开启/关闭字幕", action: #selector(toggleSubtitle)))
        row1.addArrangedSubview(makeActionButton(title: "加载示例字幕", action: #selector(loadSample)))
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "字体增大", action: #selector(fontIncrease)))
        row2.addArrangedSubview(makeActionButton(title: "字体减小", action: #selector(fontDecrease)))
        controlStack.addArrangedSubview(row2)

        let row3 = makeHStack()
        row3.addArrangedSubview(makeActionButton(title: "白色字幕", action: #selector(colorWhite)))
        row3.addArrangedSubview(makeActionButton(title: "黄色字幕", action: #selector(colorYellow)))
        controlStack.addArrangedSubview(row3)

        player.context.add(self, event: .playerSubtitleDidChange, option: .none) { [weak self] _, _ in
            self?.updateStatus()
        }
    }

    private func updateStatus() {
        let sub = player.subtitleService
        let enabled = sub?.isEnabled == true ? "开启" : "关闭"
        let fontSize = sub?.fontSize ?? 16
        statusLabel.text = "字幕状态: \(enabled) | 字号: \(Int(fontSize))pt"
    }

    @objc private func toggleSubtitle() {
        guard let sub = player.subtitleService else { return }
        sub.isEnabled.toggle()
        updateStatus()
    }

    @objc private func loadSample() {
        guard let sub = player.subtitleService else { return }
        let sampleURL = URL(string: "https://raw.githubusercontent.com/nicholasareed/sample-subtitles/master/sample.srt")!
        sub.loadSubtitle(from: sampleURL, format: .srt, language: "en")
        sub.isEnabled = true
        updateStatus()
    }

    @objc private func fontIncrease() {
        guard let sub = player.subtitleService else { return }
        sub.fontSize = min(sub.fontSize + 2, 36)
        updateStatus()
    }

    @objc private func fontDecrease() {
        guard let sub = player.subtitleService else { return }
        sub.fontSize = max(sub.fontSize - 2, 10)
        updateStatus()
    }

    @objc private func colorWhite() {
        player.subtitleService?.fontColor = .white
    }

    @objc private func colorYellow() {
        player.subtitleService?.fontColor = .yellow
    }
}
