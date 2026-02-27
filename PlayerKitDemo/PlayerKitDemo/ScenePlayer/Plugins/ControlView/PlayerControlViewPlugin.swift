//
//  PlayerControlViewPlugin.swift
//  playerkit
//
//  播控视图组件实现
//

import Foundation
import UIKit
import BizPlayerKit

/**
 * 默认播控视图，包含播放暂停、全屏、进度条、时间等控件
 */
public class PlayerDefaultControlView: UIView, PlayerControlViewProtocol {

    /**
     * 内容容器视图
     */
    private let contentView = UIView()

    /**
     * 播放暂停按钮
     */
    private let playPauseButton = UIButton(type: .system)

    /**
     * 全屏按钮
     */
    private let fullscreenButton = UIButton(type: .system)

    /**
     * 进度条
     */
    private let progressBar = UIProgressView(progressViewStyle: .default)

    /**
     * 时间标签
     */
    private let timeLabel = UILabel()

    /**
     * 使用 frame 初始化
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /**
     * 使用 coder 初始化
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /**
     * 设置界面布局
     */
    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.3)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .white
        contentView.addSubview(playPauseButton)

        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.setImage(UIImage(systemName: "arrow.up.right.and.arrow.down.left"), for: .normal)
        fullscreenButton.tintColor = .white
        contentView.addSubview(fullscreenButton)

        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = .white
        contentView.addSubview(progressBar)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.text = "00:00 / 00:00"
        contentView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),

            playPauseButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playPauseButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            fullscreenButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fullscreenButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            progressBar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            progressBar.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: fullscreenButton.leadingAnchor, constant: -20),

            timeLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 8),
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        ])
    }

    // MARK: - PlayerControlViewProtocol

    /**
     * 设置播控显示或隐藏
     */
    public func setShowControl(_ show: Bool, animated: Bool) {
        let alpha: CGFloat = show ? 1 : 0
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.alpha = alpha
            }
        } else {
            self.alpha = alpha
        }
    }

    /**
     * 设置播控锁定状态
     */
    public func setLocked(_ locked: Bool) {
        isUserInteractionEnabled = !locked
    }

    /**
     * 更新播控状态
     */
    public func updateControlState() {
    }

    // MARK: - Public Methods

    /**
     * 设置播放暂停按钮图片
     */
    public func setPlayPauseButtonImage(_ image: UIImage?, for state: UIControl.State) {
        playPauseButton.setImage(image, for: state)
    }

    /**
     * 设置时间文本
     */
    public func setTimeText(_ text: String) {
        timeLabel.text = text
    }

    /**
     * 设置进度
     */
    public func setProgress(_ progress: Float) {
        progressBar.progress = progress
    }
}

/**
 * 播控视图插件，管理播控视图的显示隐藏、锁定、自动隐藏等
 */
@MainActor
public final class PlayerControlViewPlugin: BasePlugin, PlayerControlViewService {

    /**
     * 配置模型类型
     */
    public typealias ConfigModelType = PlayerControlViewConfigModel

    // MARK: - Properties

    /**
     * 播控视图实例
     */
    private var controlViewInstance: PlayerDefaultControlView?

    /**
     * 是否显示播控
     */
    private var _isShowControl: Bool = true

    /**
     * 是否锁定播控
     */
    private var _isLocked: Bool = false

    /**
     * 播控视图是否已加载
     */
    private var _controlViewDidLoad: Bool = false

    /**
     * 自动隐藏定时器
     */
    private var autoHideTimer: Timer?

    /**
     * 强制隐藏的 key 集合
     */
    private var forceHideKeys: Set<String> = []

    /**
     * 当前模板类
     */
    private var currentTemplateClass: AnyClass?

    // MARK: - PlayerControlViewService

    /**
     * 播控视图
     */
    public var controlView: UIView? { controlViewInstance }

    /**
     * 是否显示播控
     */
    public var isShowControl: Bool {
        get { _isShowControl }
        set {
            if newValue {
                showControl(animated: true)
            } else {
                hideControl(animated: true)
            }
        }
    }

    /**
     * 是否锁定播控
     */
    public var isLocked: Bool {
        get { _isLocked }
        set {
            _isLocked = newValue
            controlViewInstance?.setLocked(_isLocked)
            context?.post(.playerControlViewDidChangeLock, object: _isLocked, sender: self)
        }
    }

    /**
     * 播控视图是否已加载
     */
    public var controlViewDidLoad: Bool { _controlViewDidLoad }

    // MARK: - Initialization

    /**
     * 初始化插件
     */
    public required init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成，创建默认播控视图
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        createDefaultControlView()

        _controlViewDidLoad = true
        self.context?.post(.playerControlViewDidLoadSticky, object: true, sender: self)

        self.context?.add(self, event: .playerPlaybackStateChanged) { [weak self] state, _ in
            guard let self = self else { return }
            if case .playing = state as? PlayerPlaybackState {
                self.resetAutoHideTimer()
            }
        }
    }

    /**
     * 配置更新
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerControlViewConfigModel else { return }

        resetAutoHideTimer()
    }

    // MARK: - Methods

    /**
     * 显示播控
     */
    public func showControl(animated: Bool) {
        guard !_isLocked && forceHideKeys.isEmpty else { return }

        _isShowControl = true
        controlViewInstance?.setShowControl(true, animated: animated)

        context?.post(.playerShowControl, object: true, sender: self)
        resetAutoHideTimer()
    }

    /**
     * 隐藏播控
     */
    public func hideControl(animated: Bool) {
        _isShowControl = false
        controlViewInstance?.setShowControl(false, animated: animated)

        context?.post(.playerShowControl, object: false, sender: self)
        cancelAutoHideTimer()
    }

    /**
     * 切换播控显示状态
     */
    public func toggleControl(animated: Bool = true) {
        if _isShowControl {
            hideControl(animated: animated)
        } else {
            showControl(animated: animated)
        }
    }

    /**
     * 锁定播控
     */
    public func lockControl() {
        isLocked = true
    }

    /**
     * 解锁播控
     */
    public func unlockControl() {
        isLocked = false
    }

    /**
     * 按 key 强制显示或隐藏播控
     */
    public func forceShowControl(_ show: Bool, forKey key: String) {
        if show {
            forceHideKeys.remove(key)
            if forceHideKeys.isEmpty {
                showControl(animated: true)
            }
        } else {
            forceHideKeys.insert(key)
            hideControl(animated: true)
        }
    }

    /**
     * 恢复指定 key 的播控显示状态
     */
    public func resumeControl(forKey key: String) {
        forceHideKeys.remove(key)
        if forceHideKeys.isEmpty {
            showControl(animated: true)
        }
    }

    /**
     * 更新播控模板
     */
    public func updateControlTemplate(_ templateClass: AnyClass?) {
        if let newTemplate = templateClass, newTemplate != currentTemplateClass {
            currentTemplateClass = newTemplate
            controlViewInstance?.removeFromSuperview()
            createDefaultControlView()
        }
        context?.post(.playerControlViewTemplateChanged, sender: self)
    }

    // MARK: - Private Methods

    /**
     * 创建默认播控视图
     */
    private func createDefaultControlView() {
        let view = PlayerDefaultControlView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        controlViewInstance = view

    }

    /**
     * 重置自动隐藏定时器
     */
    private func resetAutoHideTimer() {
        cancelAutoHideTimer()

        guard let config = configModel as? PlayerControlViewConfigModel,
              config.autoHideInterval > 0 else { return }

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: config.autoHideInterval, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.hideControl(animated: true)
            }
        }
    }

    /**
     * 取消自动隐藏定时器
     */
    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
}
