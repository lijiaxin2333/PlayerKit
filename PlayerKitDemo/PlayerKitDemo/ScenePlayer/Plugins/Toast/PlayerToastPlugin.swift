//
//  PlayerToastPlugin.swift
//  playerkit
//
//  Toast 提示组件实现
//

import Foundation

import UIKit
import PlayerKit

/**
 * Toast 消息视图，显示短时文本提示
 */
private class ToastView: UIView {
    /** 消息标签 */
    private let messageLabel = UILabel()
    /** 背景视图 */
    private let backgroundView = UIView()

    init(message: String, style: PlayerToastStyle = .info) {
        super.init(frame: .zero)
        setupUI(message: message, style: style)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * 构建 Toast UI
     */
    private func setupUI(message: String, style: PlayerToastStyle) {
        backgroundView.backgroundColor = .black.withAlphaComponent(0.8)
        backgroundView.layer.cornerRadius = 8
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        messageLabel.text = message
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 14)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(messageLabel)

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

/**
 * 加载视图，显示加载指示器和可选消息
 */
private class LoadingView: UIView {
    /** 加载指示器 */
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    /** 消息标签 */
    private let messageLabel = UILabel()
    /** 背景视图 */
    private let backgroundView = UIView()

    init(message: String? = nil) {
        super.init(frame: .zero)
        setupUI(message: message)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     * 构建加载 UI
     */
    private func setupUI(message: String?) {
        backgroundView.backgroundColor = .black.withAlphaComponent(0.8)
        backgroundView.layer.cornerRadius = 12
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        activityIndicator.color = .white
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        backgroundView.addSubview(activityIndicator)

        if let message = message {
            messageLabel.text = message
            messageLabel.textColor = .white
            messageLabel.font = .systemFont(ofSize: 14)
            messageLabel.textAlignment = .center
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.addSubview(messageLabel)
        }

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

@MainActor
/**
 * Toast 提示插件，在播放器内展示短时 Toast 和加载状态
 */
public final class PlayerToastPlugin: BasePlugin, PlayerToastService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerToastConfigModel

    /** 播放引擎服务，用于获取播放器视图 */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /** 当前显示的 Toast 视图 */
    private var currentToastView: ToastView?
    /** 当前显示的加载视图 */
    private var loadingView: LoadingView?
    /** Toast 自动隐藏定时器 */
    private var toastHideTimer: Timer?

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
     * 显示 Toast 消息
     */
    public func showToast(_ message: String, style: PlayerToastStyle = .info, duration: TimeInterval = 0) {
        let config = configModel as? PlayerToastConfigModel
        let finalDuration = duration > 0 ? duration : (config?.defaultDuration ?? 2.0)

        print("[PlayerToastPlugin] 显示 Toast: \(message), 样式: \(style)")

        hideToast()

        guard let playerView = engineService?.playerView else {
            print("[PlayerToastPlugin] 无法显示 Toast: 播放器视图不可用")
            return
        }

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

        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
        }

        toastHideTimer = Timer.scheduledTimer(withTimeInterval: finalDuration, repeats: false) { [weak self] _ in
            self?.hideToast()
        }
    }

    /**
     * 显示加载视图
     */
    public func showLoading(_ message: String? = nil) {
        print("[PlayerToastPlugin] 显示加载: \(message ?? "")")

        hideLoading()

        guard let playerView = engineService?.playerView else {
            print("[PlayerToastPlugin] 无法显示加载: 播放器视图不可用")
            return
        }

        let loading = LoadingView(message: message)
        loading.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(loading)

        NSLayoutConstraint.activate([
            loading.centerXAnchor.constraint(equalTo: playerView.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: playerView.centerYAnchor),
        ])

        loadingView = loading
    }

    /**
     * 隐藏加载视图
     */
    public func hideLoading() {
        loadingView?.removeFromSuperview()
        loadingView = nil
    }

    /**
     * 隐藏 Toast，带动画
     */
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
