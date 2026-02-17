//
//  PlayerTipManagerPlugin.swift
//  playerkit
//
//  提示管理组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 提示视图，显示带图标和消息的提示 UI
 */
private class TipView: UIView {
    /** 内容容器 */
    private let containerView = UIView()
    /** 图标视图 */
    private let iconImageView = UIImageView()
    /** 消息标签 */
    private let messageLabel = UILabel()

    init(type: PlayerTipType, message: String) {
        super.init(frame: .zero)
        setupUI(type: type, message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * 构建提示 UI，根据类型设置图标和颜色
     */
    private func setupUI(type: PlayerTipType, message: String) {
        backgroundColor = .clear

        containerView.backgroundColor = .black.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 8
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

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

@MainActor
/**
 * 提示管理插件，在播放器内展示缓冲/加载/错误等提示信息
 */
public final class PlayerTipManagerPlugin: BasePlugin, PlayerTipManagerService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerTipManagerConfigModel

    /** 播放引擎服务，用于获取播放器视图 */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /** 当前显示的提示视图，按类型索引 */
    private var visibleTips: [PlayerTipType: TipView] = [:]

    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    /**
     * 应用配置模型
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    /**
     * 显示指定类型的提示
     */
    public func showTip(_ type: PlayerTipType, message: String) {
        hideTip(type)

        guard let playerView = engineService?.playerView else {
            print("[PlayerTipManagerPlugin] 无法显示提示: 播放器视图不可用")
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

        let config = configModel as? PlayerTipManagerConfigModel
        let duration = config?.displayDuration ?? 2.0
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.hideTip(type)
        }

        print("[PlayerTipManagerPlugin] 显示提示: \(type) - \(message)")
    }

    /**
     * 隐藏指定类型的提示
     */
    public func hideTip(_ type: PlayerTipType) {
        guard let tipView = visibleTips.removeValue(forKey: type) else { return }

        UIView.animate(withDuration: 0.25, animations: {
            tipView.alpha = 0
        }) { _ in
            tipView.removeFromSuperview()
        }

        print("[PlayerTipManagerPlugin] 隐藏提示: \(type)")
    }

    /**
     * 隐藏所有提示
     */
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
        print("[PlayerTipManagerPlugin] 隐藏所有提示，数量: \(count)")
    }

    /**
     * 显示缓冲中提示
     */
    public func showBufferingTip() {
        showTip(.buffering, message: "缓冲中...")
    }

    /**
     * 显示加载中提示
     */
    public func showLoadingTip(_ message: String = "加载中...") {
        showTip(.loading, message: message)
    }

    /**
     * 显示错误提示
     */
    public func showErrorTip(_ message: String) {
        showTip(.error, message: message)
    }

    /**
     * 显示警告提示
     */
    public func showWarningTip(_ message: String) {
        showTip(.warning, message: message)
    }

    /**
     * 显示信息提示
     */
    public func showInfoTip(_ message: String) {
        showTip(.info, message: message)
    }
}
