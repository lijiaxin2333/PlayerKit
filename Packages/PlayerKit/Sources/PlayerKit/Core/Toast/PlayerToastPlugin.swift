//
//  PlayerToastPlugin.swift
//  playerkit
//
//  Toast 提示组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Toast 视图

private class ToastView: UIView {
    private let messageLabel = UILabel()
    private let backgroundView = UIView()

    init(message: String, style: PlayerToastStyle = .info) {
        super.init(frame: .zero)
        setupUI(message: message, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(message: String, style: PlayerToastStyle) {
        // 背景视图
        backgroundView.backgroundColor = .black.withAlphaComponent(0.8)
        backgroundView.layer.cornerRadius = 8
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        // 消息标签
        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(messageLabel)

        // 布局
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundView.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            backgroundView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            backgroundView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),

            messageLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -12),
        ])
    }
}

// MARK: - 加载视图

private class LoadingView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let backgroundView = UIView()

    init(message: String? = nil) {
        super.init(frame: .zero)
        setupUI(message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(message: String?) {
        // 背景视图
        backgroundView.backgroundColor = .black.withAlphaComponent(0.8)
        backgroundView.layer.cornerRadius = 12
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        // 指示器
        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        backgroundView.addSubview(activityIndicator)

        // 消息标签
        if let message = message {
            messageLabel.text = message
            messageLabel.textColor = .white
            messageLabel.font = .systemFont(ofSize: 14)
            messageLabel.textAlignment = .center
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(messageLabel)
        }

        // 布局
        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),

            activityIndicator.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),

            messageLabel.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -16),
        ])
    }
}

// MARK: - Toast 提示组件

@MainActor
public final class PlayerToastPlugin: BasePlugin, PlayerToastService {

    public typealias ConfigModelType = PlayerToastConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var currentToastView: ToastView?
    private var loadingView: LoadingView?
    private var toastHideTimer: Timer?

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerToastService

    public func showToast(_ message: String, style: PlayerToastStyle = .info, duration: TimeInterval = 0) {
        let config = configModel as? PlayerToastConfigModel
        let finalDuration = duration > 0 ? duration : (config?.defaultDuration ?? 2.0)

        print("[PlayerToastPlugin] 显示 Toast: \(message), 样式: \(style)")

        // 移除旧的 Toast
        hideToast()

        // 获取播放器视图作为父视图
        guard let playerView = engineService?.playerView else {
            print("[PlayerToastPlugin] 无法显示 Toast: 播放器视图不可用")
            return
        }

        // 创建新的 Toast
        let toast = ToastView(message: message, style: style)
        toast.translatesAutoresizingMaskIntoConstraints = false
        toast.alpha = 0
        playerView.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
            toast.leadingAnchor.constraint(greaterThanOrEqualTo: playerView.leadingAnchor, constant: 40),
            toast.trailingAnchor.constraint(lessThanOrEqualTo: playerView.trailingAnchor, constant: -40),
        ])

        currentToastView = toast

        // 动画显示
        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        }

        // 自动隐藏
        toastHideTimer = Timer.scheduledTimer(withTimeInterval: finalDuration, repeats: false) { [weak self] _ in
            self?.hideToast()
        }
    }

    public func showLoading(_ message: String? = nil) {
        print("[PlayerToastPlugin] 显示加载: \(message ?? "")")

        // 移除旧的加载视图
        hideLoading()

        // 获取播放器视图作为父视图
        guard let playerView = engineService?.playerView else {
            print("[PlayerToastPlugin] 无法显示加载: 播放器视图不可用")
            return
        }

        // 创建加载视图
        let loading = LoadingView(message: message)
        loading.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(loading)

        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
        ])

        loadingView = loading
    }

    public func hideLoading() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    // MARK: - Private Methods

    private func hideToast() {
        toastHideTimer?.invalidate()
        toastHideTimer = nil

        UIView.animate(withDuration: 0.25, animations: {
            self.currentToastView?.alpha = 0
        }) { _ in
            self.currentToastView?.removeFromSuperview()
            self.currentToastView = nil
        }
    }
}
