//
//  PlayerControlViewPlugin.swift
//  playerkit
//
//  播控视图组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 默认播控视图

public class PlayerDefaultControlView: UIView, PlayerControlViewProtocol {

    private let contentView = UIView()
    private let playPauseButton = UIButton(type: .system)
    private let fullscreenButton = UIButton(type: .system)
    private let progressBar = UIProgressView(progressViewStyle: .default)
    private let timeLabel = UILabel()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.3)

        // 内容视图
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        // 播放/暂停按钮
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        playPauseButton.tintColor = .white
        contentView.addSubview(playPauseButton)

        // 全屏按钮
        fullscreenButton.translatesAutoresizingMaskIntoConstraints = false
        fullscreenButton.setImage(UIImage(systemName: "arrow.up.right.and.arrow.down.left"), for: .normal)
        fullscreenButton.tintColor = .white
        contentView.addSubview(fullscreenButton)

        // 进度条
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = .white
        contentView.addSubview(progressBar)

        // 时间标签
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.textColor = .white
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        timeLabel.text = "00:00 / 00:00"
        contentView.addSubview(timeLabel)

        // 布局
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

    public func setLocked(_ locked: Bool) {
        isUserInteractionEnabled = !locked
    }

    public func updateControlState() {
        // 更新播控状态
    }

    // MARK: - Public Methods

    public func setPlayPauseButtonImage(_ image: UIImage?, for state: UIControl.State) {
        playPauseButton.setImage(image, for: state)
    }

    public func setTimeText(_ text: String) {
        timeLabel.text = text
    }

    public func setProgress(_ progress: Float) {
        progressBar.progress = progress
    }
}

// MARK: - 播控视图组件

@MainActor
public final class PlayerControlViewPlugin: BasePlugin, PlayerControlViewService {

    public typealias ConfigModelType = PlayerControlViewConfigModel

    // MARK: - Properties

    private var controlViewInstance: PlayerDefaultControlView?
    private var _isShowControl: Bool = true
    private var _isLocked: Bool = false
    private var _controlViewDidLoad: Bool = false
    private var autoHideTimer: Timer?
    private var forceHideKeys: Set<String> = []
    private var currentTemplateClass: AnyClass?

    // MARK: - PlayerControlViewService

    public var controlView: UIView? { controlViewInstance }

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

    public var isLocked: Bool {
        get { _isLocked }
        set {
            _isLocked = newValue
            controlViewInstance?.setLocked(_isLocked)
            context?.post(.playerControlViewDidChangeLock, object: _isLocked, sender: self)
        }
    }

    public var controlViewDidLoad: Bool { _controlViewDidLoad }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 创建默认播控视图
        createDefaultControlView()

        _controlViewDidLoad = true
        self.context?.post(.playerControlViewDidLoadSticky, object: true, sender: self)

        // 监听播放状态变化，自动显示播控
        self.context?.add(self, event: .playerPlaybackStateChanged) { [weak self] state, _ in
            guard let self = self else { return }
            if case .playing = state as? PlayerPlaybackState {
                self.resetAutoHideTimer()
            }
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerControlViewConfigModel else { return }

        resetAutoHideTimer()
    }

    // MARK: - Methods

    public func showControl(animated: Bool) {
        guard !_isLocked && forceHideKeys.isEmpty else { return }

        _isShowControl = true
        controlViewInstance?.setShowControl(true, animated: animated)

        context?.post(.playerShowControl, object: true, sender: self)
        resetAutoHideTimer()
    }

    public func hideControl(animated: Bool) {
        _isShowControl = false
        controlViewInstance?.setShowControl(false, animated: animated)

        context?.post(.playerShowControl, object: false, sender: self)
        cancelAutoHideTimer()
    }

    public func toggleControl(animated: Bool = true) {
        if _isShowControl {
            hideControl(animated: animated)
        } else {
            showControl(animated: animated)
        }
    }

    public func lockControl() {
        isLocked = true
    }

    public func unlockControl() {
        isLocked = false
    }

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

    public func resumeControl(forKey key: String) {
        forceHideKeys.remove(key)
        if forceHideKeys.isEmpty {
            showControl(animated: true)
        }
    }

    public func updateControlTemplate(_ templateClass: AnyClass?) {
        print("[PlayerControlViewPlugin] 更新播控模板: \(String(describing: templateClass))")

        // 如果模板类型变化，重新创建播控视图
        if let newTemplate = templateClass, newTemplate != currentTemplateClass {
            currentTemplateClass = newTemplate

            // 移除旧视图
            controlViewInstance?.removeFromSuperview()

            // 创建新视图（这里简化处理，实际应该根据模板类创建）
            createDefaultControlView()
        }

        context?.post(.playerControlViewTemplateChanged, sender: self)
    }

    // MARK: - Public Methods

    public func updatePlayPauseButton(isPlaying: Bool) {
        let imageName = isPlaying ? "pause.fill" : "play.fill"
        let image = UIImage(systemName: imageName)
        controlViewInstance?.setPlayPauseButtonImage(image, for: .normal)
    }

    public func updateTimeText(_ text: String) {
        controlViewInstance?.setTimeText(text)
    }

    public func updateProgress(_ progress: Float) {
        controlViewInstance?.setProgress(progress)
    }

    // MARK: - Private Methods

    private func createDefaultControlView() {
        let view = PlayerDefaultControlView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        controlViewInstance = view

        print("[PlayerControlViewPlugin] 创建默认播控视图")
    }

    private func resetAutoHideTimer() {
        cancelAutoHideTimer()

        guard let config = configModel as? PlayerControlViewConfigModel,
              config.autoHideInterval > 0 else { return }

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: config.autoHideInterval, repeats: false) { [weak self] _ in
            self?.hideControl(animated: true)
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
}
