import UIKit
import PlayerKit

@MainActor
final class SnapshotDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示视频截图功能：支持同步截取当前帧、异步截取当前帧，以及指定时间点生成缩略图。"
    }

    override var demoPlugins: [String] {
        ["PlayerSnapshotPlugin", "PlayerTimeControlPlugin", "PlayerProcessPlugin"]
    }

    private let previewImageView = UIImageView()
    private let infoLabel = UILabel()

    override func onPlayerReady() {
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.textColor = .secondaryLabel
        infoLabel.text = "点击按钮截取视频画面"
        controlStack.addArrangedSubview(infoLabel)

        let row1 = makeHStack()
        row1.addArrangedSubview(makeActionButton(title: "截取当前帧", action: #selector(captureSync)))
        row1.addArrangedSubview(makeActionButton(title: "异步截取", action: #selector(captureAsync)))
        controlStack.addArrangedSubview(row1)

        let row2 = makeHStack()
        row2.addArrangedSubview(makeActionButton(title: "截取第5秒", action: #selector(captureAt5)))
        row2.addArrangedSubview(makeActionButton(title: "截取第10秒", action: #selector(captureAt10)))
        controlStack.addArrangedSubview(row2)

        previewImageView.contentMode = .scaleAspectFit
        previewImageView.backgroundColor = .tertiarySystemBackground
        previewImageView.layer.cornerRadius = 8
        previewImageView.clipsToBounds = true
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        controlStack.addArrangedSubview(previewImageView)
    }

    @objc private func captureSync() {
        guard let snapshot = player.snapshotService else { return }
        let image = snapshot.currentFrameImage(size: nil)
        previewImageView.image = image
        let time = player.context.resolveService(PlayerTimeControlService.self)?.currentTime ?? 0
        infoLabel.text = "同步截取 @ \(String(format: "%.1f", time))s"
    }

    @objc private func captureAsync() {
        guard let snapshot = player.snapshotService else { return }
        infoLabel.text = "截取中..."
        snapshot.currentFrameImage { [weak self] image in
            self?.previewImageView.image = image
            self?.infoLabel.text = "异步截取完成"
        }
    }

    @objc private func captureAt5() {
        captureAtTime(5)
    }

    @objc private func captureAt10() {
        captureAtTime(10)
    }

    private func captureAtTime(_ time: TimeInterval) {
        guard let snapshot = player.snapshotService else { return }
        infoLabel.text = "生成缩略图 @ \(time)s ..."
        snapshot.generateThumbnail(at: time, size: CGSize(width: 320, height: 180)) { [weak self] image in
            self?.previewImageView.image = image
            self?.infoLabel.text = "缩略图 @ \(time)s 生成完成"
        }
    }
}
