import UIKit
import PlayerKit

@MainActor
class PluginDemoBaseViewController: UIViewController {

    let player = Player(name: "PluginDemo")
    let playerContainer = UIView()
    let descriptionLabel = UILabel()
    let controlStack = UIStackView()

    var demoDescription: String { "" }
    var demoPlugins: [String] { [] }

    /// 场景层插件注册器（子类可重写来注册场景层插件）
    var sceneRegProvider: RegisterProvider? { nil }

    private var video: ShowcaseVideo?

    override func viewDidLoad() {
        super.viewDidLoad()

        // 注册场景层插件（如果有）
        if let provider = sceneRegProvider {
            player.context.addRegProvider(provider)
        }

        view.backgroundColor = .systemBackground
        setupLayout()
        loadVideoAndPlay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            player.engineService?.pause()
            player.engineService?.replaceCurrentItem(with: nil)
        }
    }

    private func setupLayout() {
        playerContainer.backgroundColor = .black
        playerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerContainer)

        let infoCard = UIView()
        infoCard.backgroundColor = .secondarySystemBackground
        infoCard.layer.cornerRadius = 12
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(infoCard)

        descriptionLabel.text = demoDescription
        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(descriptionLabel)

        let pluginTitle = UILabel()
        pluginTitle.text = "演示插件"
        pluginTitle.font = .systemFont(ofSize: 13, weight: .semibold)
        pluginTitle.textColor = .label
        pluginTitle.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(pluginTitle)

        let pluginTagContainer = UIView()
        pluginTagContainer.translatesAutoresizingMaskIntoConstraints = false
        infoCard.addSubview(pluginTagContainer)

        var tagViews: [UIView] = []
        for name in demoPlugins {
            let tag = makePillLabel(name)
            pluginTagContainer.addSubview(tag)
            tagViews.append(tag)
        }

        let tagFlow = FlowLayout(views: tagViews, container: pluginTagContainer, spacing: 6, lineSpacing: 6)
        tagFlow.layout()

        controlStack.axis = .vertical
        controlStack.spacing = 12
        controlStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlStack)

        NSLayoutConstraint.activate([
            playerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            playerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerContainer.heightAnchor.constraint(equalTo: playerContainer.widthAnchor, multiplier: 9.0 / 16.0),

            infoCard.topAnchor.constraint(equalTo: playerContainer.bottomAnchor, constant: 16),
            infoCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            infoCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),

            pluginTitle.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),
            pluginTitle.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),

            pluginTagContainer.topAnchor.constraint(equalTo: pluginTitle.bottomAnchor, constant: 6),
            pluginTagContainer.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 12),
            pluginTagContainer.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -12),
            pluginTagContainer.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -12),

            controlStack.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 16),
            controlStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            controlStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
    }

    private func loadVideoAndPlay() {
        let ds = ShowcaseDataSource.shared
        let existing = ds.videos
        if let first = existing.first {
            video = first
            startPlayback(first)
        } else {
            ds.fetchFeed { [weak self] videos, _ in
                guard let self, let first = videos.first else { return }
                MainActor.assumeIsolated {
                    self.video = first
                    self.startPlayback(first)
                }
            }
        }
    }

    private func startPlayback(_ video: ShowcaseVideo) {
        let config = PlayerEngineCoreConfigModel()
        config.autoPlay = true
        player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: config)

        let dataConfig = PlayerDataConfigModel()
        var dataModel = PlayerDataModel()
        dataModel.videoURL = video.url
        dataModel.title = video.title
        dataModel.author = video.creator.nickname
        dataModel.coverURL = video.coverURL
        dataModel.videoWidth = video.width
        dataModel.videoHeight = video.height
        dataModel.duration = video.duration
        dataConfig.initialDataModel = dataModel
        player.dataService?.config(dataConfig)

        guard let pv = player.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        playerContainer.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: playerContainer.topAnchor),
            pv.leadingAnchor.constraint(equalTo: playerContainer.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: playerContainer.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: playerContainer.bottomAnchor),
        ])

        onPlayerReady()
    }

    func onPlayerReady() {}

    // MARK: - Helpers

    func makeActionButton(title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }

    func makeHStack(spacing: CGFloat = 12) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = spacing
        stack.distribution = .fillEqually
        return stack
    }

    func makeInfoLabel() -> UILabel {
        let lbl = UILabel()
        lbl.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        lbl.textColor = .secondaryLabel
        lbl.numberOfLines = 0
        return lbl
    }

    private func makePillLabel(_ text: String) -> UIView {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = .systemFont(ofSize: 11, weight: .medium)
        lbl.textColor = .systemBlue
        lbl.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        lbl.layer.cornerRadius = 4
        lbl.clipsToBounds = true
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let size = lbl.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20))
        NSLayoutConstraint.activate([
            lbl.widthAnchor.constraint(equalToConstant: size.width + 12),
            lbl.heightAnchor.constraint(equalToConstant: 22),
        ])
        return lbl
    }
}

// MARK: - Simple Flow Layout

private struct FlowLayout {
    let views: [UIView]
    let container: UIView
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func layout() {
        guard !views.isEmpty else {
            container.heightAnchor.constraint(equalToConstant: 0).isActive = true
            return
        }

        let maxWidth: CGFloat = UIScreen.main.bounds.width - 56
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for v in views {
            let size = v.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += lineHeight + lineSpacing
                lineHeight = 0
            }
            v.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        container.heightAnchor.constraint(equalToConstant: y + lineHeight).isActive = true
    }
}
