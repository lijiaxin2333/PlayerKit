import UIKit
import BizPlayerKit

@MainActor
/**
 * 倍速选择面板视图，从底部弹出的倍速选择 UI，支持多种倍率
 */
final class PlayerSpeedPanelView: UIView {

    /** 选中某倍速时的回调 */
    var onSelectSpeed: ((Float) -> Void)?
    /** 点击遮罩关闭时的回调 */
    var onDismiss: (() -> Void)?

    /** 底部内容容器视图 */
    private let containerView = UIView()
    /** 半透明遮罩视图 */
    private let dimView = UIView()
    /** 标题标签 */
    private let titleLabel = UILabel()
    /** 倍速按钮水平栈 */
    private let speedStack = UIStackView()
    /** 倍速按钮数组 */
    private var speedButtons: [UIButton] = []
    /** 面板高度 */
    private let panelHeight: CGFloat = 260

    /** 支持的倍速与显示文案 */
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

    /**
     * 构建 UI，包括遮罩、容器、标题、倍速按钮和长按提示
     */
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

    /**
     * 根据当前倍速更新按钮选中状态
     */
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

    /**
     * 以从底部滑入动画展示面板
     */
    func showAnimated() {
        containerView.transform = CGAffineTransform(translationX: 0, y: panelHeight)
        dimView.alpha = 0
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
            self.dimView.alpha = 1
        }
    }

    /**
     * 以滑出动画关闭面板
     */
    func dismissAnimated(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn, animations: {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.panelHeight)
            self.dimView.alpha = 0
        }) { _ in
            self.removeFromSuperview()
            completion?()
        }
    }

    /**
     * 倍速按钮点击处理
     */
    @objc private func speedButtonTapped(_ sender: UIButton) {
        let rate = Float(sender.tag) / 100.0
        updateSelection(currentSpeed: rate)
        onSelectSpeed?(rate)
    }

    /**
     * 遮罩点击处理，触发关闭
     */
    @objc private func dimTapped() {
        onDismiss?()
    }
}
