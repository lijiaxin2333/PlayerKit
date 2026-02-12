//
//  PlayerTipManagerComp.swift
//  playerkit
//
//  提示管理组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 提示视图

private class TipView: UIView {
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let messageLabel = UILabel()

    init(type: PlayerTipType, message: String) {
        super.init(frame: .zero)
        setupUI(type: type, message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(type: PlayerTipType, message: String) {
        backgroundColor = .clear

        containerView.backgroundColor = .black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        // 设置图标
        let iconName: String?
        let tintColor: UIColor
        switch type {
        case .buffering:
            iconName = "arrow.triangle.2.circlepath"
            tintColor = .systemBlue
        case .loading:
            iconName = "hourglass"
            tintColor = .systemYellow
        case .error:
            iconName = "xmark.circle.fill"
            tintColor = .systemRed
        case .warning:
            iconName = "exclamationmark.triangle.fill"
            tintColor = .systemOrange
        case .info:
            iconName = "info.circle.fill"
            tintColor = .systemBlue
        }

        if let iconName = iconName {
            let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
            iconImageView.image = UIImage(systemName: iconName, withConfiguration: config)
            iconImageView.tintColor = tintColor
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(iconImageView)

        // 消息标签
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40),

            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),

            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            iconImageView.topAnchor.constraint(equalTo: messageLabel.topAnchor),
        ])
    }
}

// MARK: - 提示管理组件

@MainActor
public final class PlayerTipManagerComp: CCLBaseComp, PlayerTipManagerService {

    public typealias ConfigModelType = PlayerTipManagerConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var visibleTips: [PlayerTipType: TipView] = [:]

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerTipManagerService

    public func showTip(_ type: PlayerTipType, message: String) {
        // 同一类型只显示一个
        hideTip(type)

        guard let playerView = engineService?.playerView else {
            print("[PlayerTipManagerComp] 无法显示提示: 播放器视图不可用")
            return
        }

        let tipView = TipView(type: type, message: message)
        tipView.translatesAutoresizingMaskIntoConstraints = false
        tipView.alpha = 0
        playerView.addSubview(tipView)

        NSLayoutConstraint.activate([
            tipView.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            tipView.topAnchor.constraint(equalTo: playerView.safeAreaLayoutGuide.topAnchor, constant: 80),
            tipView.leadingAnchor.constraint(greaterThanOrEqualTo: playerView.leadingAnchor, constant: 40),
            tipView.trailingAnchor.constraint(lessThanOrEqualTo: playerView.trailingAnchor, constant: -40),
        ])

        visibleTips[type] = tipView

        UIView.animate(withDuration: 0.25) {
            tipView.alpha = 1
        }

        // 自动隐藏
        let config = configModel as? PlayerTipManagerConfigModel
        let duration = config?.displayDuration ?? 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.hideTip(type)
        }

        print("[PlayerTipManagerComp] 显示提示: \(type) - \(message)")
    }

    public func hideTip(_ type: PlayerTipType) {
        guard let tipView = visibleTips.removeValue(forKey: type) else { return }

        UIView.animate(withDuration: 0.25, animations: {
            tipView.alpha = 0
        }) { _ in
            tipView.removeFromSuperview()
        }

        print("[PlayerTipManagerComp] 隐藏提示: \(type)")
    }

    public func hideAllTips() {
        let count = visibleTips.count
        visibleTips.values.forEach { tipView in
            UIView.animate(withDuration: 0.25, animations: {
                tipView.alpha = 0
            }) { _ in
                tipView.removeFromSuperview()
            }
        }
        visibleTips.removeAll()
        print("[PlayerTipManagerComp] 隐藏所有提示，数量: \(count)")
    }

    // MARK: - Convenience Methods

    public func showBufferingTip() {
        showTip(.buffering, message: "缓冲中...")
    }

    public func showLoadingTip(_ message: String = "加载中...") {
        showTip(.loading, message: message)
    }

    public func showErrorTip(_ message: String) {
        showTip(.error, message: message)
    }

    public func showWarningTip(_ message: String) {
        showTip(.warning, message: message)
    }

    public func showInfoTip(_ message: String) {
        showTip(.info, message: message)
    }
}
