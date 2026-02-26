import UIKit
import PlayerKit

// MARK: - Gradient Layer

@MainActor
public final class ShowcaseFeedGradientView: UIView {

    private let gradientLayer = CAGradientLayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        gradientLayer.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.locations = [0.0, 1.0]
        layer.addSublayer(gradientLayer)
    }

    required init?(coder: NSCoder) { fatalError() }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = CGRect(
            x: 0,
            y: bounds.height * 0.55,
            width: bounds.width,
            height: bounds.height * 0.45
        )
    }
}

// MARK: - Info Layer

@MainActor
public final class ShowcaseFeedInfoView: UIView {

    public weak var overlayContext: ContextProtocol?
    private(set) public var videoIndex: Int = 0

    private let avatarImageView = UIImageView()
    private let authorLabel = UILabel()
    private let descLabel = UILabel()
    private var avatarTask: URLSessionDataTask?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.layer.cornerRadius = 18
        avatarImageView.layer.borderWidth = 1.5
        avatarImageView.layer.borderColor = UIColor.white.cgColor
        avatarImageView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(avatarTapped)))
        addSubview(avatarImageView)

        authorLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        authorLabel.textColor = .white
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        applyShadow(authorLabel)
        addSubview(authorLabel)

        descLabel.font = .systemFont(ofSize: 13)
        descLabel.textColor = .white
        descLabel.numberOfLines = 2
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        applyShadow(descLabel)
        addSubview(descLabel)

        NSLayoutConstraint.activate([
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 36),
            avatarImageView.heightAnchor.constraint(equalToConstant: 36),
            avatarImageView.bottomAnchor.constraint(equalTo: descLabel.topAnchor, constant: -8),

            authorLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 10),
            authorLabel.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),
            authorLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -70),

            descLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            descLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -70),
            descLabel.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    public func configure(video: ShowcaseVideo, index: Int) {
        videoIndex = index
        authorLabel.text = "@\(video.creator.nickname)"
        descLabel.text = video.desc.isEmpty ? video.title : video.desc
        loadAvatar(video.creator.avatarURL)
    }

    @objc private func avatarTapped() {
        overlayContext?.post(.showcaseOverlayDidTapAvatar, object: videoIndex, sender: self)
    }

    private func loadAvatar(_ url: URL?) {
        avatarTask?.cancel()
        avatarImageView.image = nil
        guard let url = url else { return }
        avatarTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.avatarImageView.image = image }
        }
        avatarTask?.resume()
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}

// MARK: - Social Layer

@MainActor
public final class ShowcaseFeedSocialView: UIView {

    public weak var overlayContext: ContextProtocol?
    private(set) public var videoIndex: Int = 0

    private let likeButton = UIButton(type: .system)
    private let likeCountLabel = UILabel()
    private let commentButton = UIButton(type: .system)
    private let commentCountLabel = UILabel()
    private let shareButton = UIButton(type: .system)
    private let shareCountLabel = UILabel()
    private let detailButton = UIButton(type: .system)

    private var isLiked = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)

        stack.addArrangedSubview(makeGroup(icon: "heart", config: iconConfig, button: likeButton, label: likeCountLabel, action: #selector(likeTapped)))
        stack.addArrangedSubview(makeGroup(icon: "bubble.right", config: iconConfig, button: commentButton, label: commentCountLabel, action: #selector(commentTapped)))
        stack.addArrangedSubview(makeGroup(icon: "arrowshape.turn.up.right", config: iconConfig, button: shareButton, label: shareCountLabel, action: #selector(shareTapped)))

        let detailConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        detailButton.setImage(UIImage(systemName: "arrow.up.right.square", withConfiguration: detailConfig), for: .normal)
        detailButton.tintColor = .white
        detailButton.translatesAutoresizingMaskIntoConstraints = false
        detailButton.addTarget(self, action: #selector(detailTapped), for: .touchUpInside)
        applyShadow(detailButton)
        stack.addArrangedSubview(detailButton)

        NSLayoutConstraint.activate([
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -16),
            detailButton.widthAnchor.constraint(equalToConstant: 44),
            detailButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    public func configure(video: ShowcaseVideo, index: Int) {
        videoIndex = index
        likeCountLabel.text = Self.formatCount(video.likeCount)
        commentCountLabel.text = Self.formatCount(video.commentCount)
        shareCountLabel.text = Self.formatCount(video.shareCount)
        isLiked = video.isLiked
        updateLikeIcon()
    }

    @objc private func likeTapped() {
        isLiked.toggle()
        updateLikeIcon()
        if isLiked {
            UIView.animate(withDuration: 0.1, animations: {
                self.likeButton.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            }) { _ in
                UIView.animate(withDuration: 0.1) { self.likeButton.transform = .identity }
            }
        }
        overlayContext?.post(.showcaseOverlayDidTapLike, object: videoIndex, sender: self)
    }

    @objc private func commentTapped() {
        overlayContext?.post(.showcaseOverlayDidTapComment, object: videoIndex, sender: self)
    }

    @objc private func shareTapped() {
        overlayContext?.post(.showcaseOverlayDidTapShare, object: videoIndex, sender: self)
    }

    @objc private func detailTapped() {
        overlayContext?.post(.showcaseOverlayDidTapDetail, object: videoIndex, sender: self)
    }

    private func updateLikeIcon() {
        let cfg = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        if isLiked {
            likeButton.setImage(UIImage(systemName: "heart.fill", withConfiguration: cfg), for: .normal)
            likeButton.tintColor = UIColor(red: 1, green: 0.25, blue: 0.35, alpha: 1)
        } else {
            likeButton.setImage(UIImage(systemName: "heart", withConfiguration: cfg), for: .normal)
            likeButton.tintColor = .white
        }
    }

    private func makeGroup(icon: String, config: UIImage.SymbolConfiguration, button: UIButton, label: UILabel, action: Selector) -> UIView {
        let c = UIView()
        c.translatesAutoresizingMaskIntoConstraints = false

        button.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: action, for: .touchUpInside)
        applyShadow(button)
        c.addSubview(button)

        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        applyShadow(label)
        c.addSubview(label)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: c.topAnchor),
            button.centerXAnchor.constraint(equalTo: c.centerXAnchor),
            button.widthAnchor.constraint(equalToConstant: 34),
            button.heightAnchor.constraint(equalToConstant: 34),
            label.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: c.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: c.bottomAnchor),
            c.widthAnchor.constraint(equalToConstant: 44),
        ])
        return c
    }

    public static func formatCount(_ count: Int) -> String {
        if count <= 0 { return "" }
        if count >= 10000 { return String(format: "%.1fw", Double(count) / 10000.0) }
        if count >= 1000 { return String(format: "%.1fk", Double(count) / 1000.0) }
        return "\(count)"
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}

// MARK: - Overlay Plugin

@MainActor
public final class ShowcaseFeedOverlayPlugin: BasePlugin, ShowcaseFeedOverlayService {

    public let gradientView = ShowcaseFeedGradientView()
    public let infoView = ShowcaseFeedInfoView()
    public let socialView = ShowcaseFeedSocialView()
    private var isInstalled = false

    @PlayerPlugin private var feedDataService: ShowcaseFeedDataService?
    @PlayerPlugin private var cellViewService: ShowcaseFeedCellViewService?

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        infoView.overlayContext = context
        socialView.overlayContext = context

        context.add(self, event: .showcaseFeedDataDidUpdate) { [weak self] _, _ in
            guard let self = self else { return }
            self.installIfNeeded()
            guard let video = self.feedDataService?.video else { return }
            let index = self.feedDataService?.videoIndex ?? 0
            self.infoView.configure(video: video, index: index)
            self.socialView.configure(video: video, index: index)
        }
    }

    public func bringOverlaysToFront() {
        guard let contentView = cellViewService?.contentView else { return }
        contentView.bringSubviewToFront(gradientView)
        contentView.bringSubviewToFront(infoView)
        contentView.bringSubviewToFront(socialView)
    }

    private func installIfNeeded() {
        guard !isInstalled else { return }
        guard let contentView = cellViewService?.contentView else { return }

        for view in [gradientView as UIView, infoView, socialView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: contentView.topAnchor),
                view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            ])
        }
        isInstalled = true
    }
}

// MARK: - Shadow Helper

private func applyShadow(_ view: UIView) {
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOffset = CGSize(width: 0, height: 1)
    view.layer.shadowOpacity = 0.45
    view.layer.shadowRadius = 2
}
