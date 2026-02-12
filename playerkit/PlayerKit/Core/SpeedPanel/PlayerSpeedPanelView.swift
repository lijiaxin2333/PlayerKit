import UIKit

@MainActor
final class PlayerSpeedPanelView: UIView {

    var onSelectSpeed: ((Float) -> Void)?
    var onDismiss: (() -> Void)?

    private let containerView = UIView()
    private let dimView = UIView()
    private let titleLabel = UILabel()
    private let speedStack = UIStackView()
    private var speedButtons: [UIButton] = []
    private let panelHeight: CGFloat = 260

    private let speeds: [(Float, String)] = [
        (0.5, "0.5x"),
        (0.75, "0.75x"),
        (1.0, "正常"),
        (1.25, "1.25x"),
        (1.5, "1.5x"),
        (2.0, "2x"),
        (3.0, "3x"),
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.translatesAutoresizingMaskIntoConstraints = false
        dimView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dimTapped)))
        addSubview(dimView)

        containerView.backgroundColor = UIColor(white: 0.12, alpha: 1)
        containerView.layer.cornerRadius = 16
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        let handleBar = UIView()
        handleBar.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        handleBar.layer.cornerRadius = 2
        handleBar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(handleBar)

        titleLabel.text = "倍速"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)

        speedStack.axis = .horizontal
        speedStack.distribution = .fillEqually
        speedStack.spacing = 8
        speedStack.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(speedStack)

        for (rate, name) in speeds {
            let btn = UIButton(type: .system)
            btn.setTitle(name, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            btn.tintColor = .white
            btn.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            btn.layer.cornerRadius = 20
            btn.tag = Int(rate * 100)
            btn.addTarget(self, action: #selector(speedButtonTapped(_:)), for: .touchUpInside)
            btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
            speedStack.addArrangedSubview(btn)
            speedButtons.append(btn)
        }

        let longPressHint = UILabel()
        longPressHint.text = "长按视频可临时2倍速播放"
        longPressHint.font = .systemFont(ofSize: 12)
        longPressHint.textColor = UIColor.white.withAlphaComponent(0.4)
        longPressHint.textAlignment = .center
        longPressHint.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(longPressHint)

        NSLayoutConstraint.activate([
            dimView.topAnchor.constraint(equalTo: topAnchor),
            dimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: panelHeight),

            handleBar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            handleBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            handleBar.widthAnchor.constraint(equalToConstant: 36),
            handleBar.heightAnchor.constraint(equalToConstant: 4),

            titleLabel.topAnchor.constraint(equalTo: handleBar.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),

            speedStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            speedStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            speedStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            longPressHint.topAnchor.constraint(equalTo: speedStack.bottomAnchor, constant: 20),
            longPressHint.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }

    func updateSelection(currentSpeed: Float) {
        let currentTag = Int(currentSpeed * 100)
        for btn in speedButtons {
            let selected = btn.tag == currentTag
            btn.backgroundColor = selected
                ? UIColor.white.withAlphaComponent(0.25)
                : UIColor.white.withAlphaComponent(0.08)
            btn.titleLabel?.font = selected
                ? .systemFont(ofSize: 14, weight: .bold)
                : .systemFont(ofSize: 14, weight: .medium)
        }
    }

    func showAnimated() {
        containerView.transform = CGAffineTransform(translationX: 0, y: panelHeight)
        dimView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
            self.dimView.alpha = 1
        }
    }

    func dismissAnimated(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.panelHeight)
            self.dimView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    @objc private func speedButtonTapped(_ sender: UIButton) {
        let rate = Float(sender.tag) / 100.0
        updateSelection(currentSpeed: rate)
        onSelectSpeed?(rate)
    }

    @objc private func dimTapped() {
        onDismiss?()
    }
}
