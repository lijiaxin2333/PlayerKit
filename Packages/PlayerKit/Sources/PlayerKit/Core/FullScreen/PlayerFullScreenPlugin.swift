//
//  PlayerFullScreenPlugin.swift
//  playerkit
//
//  全屏管理组件实现
//

import Foundation
import AVFoundation
import AVKit
import UIKit

// MARK: - 全屏播控视图

/// 全屏状态下的播控视图
public class PlayerFullScreenControlView: UIView {

    // MARK: - UI Components

    /// 关闭按钮
    public private(set) var closeButton: UIButton!

    /// 播放/暂停按钮
    public private(set) var playPauseButton: UIButton!

    /// 进度条
    public private(set) var progressSlider: UISlider!

    /// 当前时间标签
    public private(set) var currentTimeLabel: UILabel!

    /// 总时长标签
    public private(set) var durationLabel: UILabel!

    /// 倍速按钮
    public private(set) var speedButton: UIButton!

    /// 底部工具栏
    private var bottomToolbar: UIView!

    /// 顶部工具栏
    private var topToolbar: UIView!

    // MARK: - Callbacks

    /// 关闭按钮点击回调
    public var onCloseTapped: (() -> Void)?

    /// 播放/暂停点击回调
    public var onPlayPauseTapped: (() -> Void)?

    /// 进度改变回调
    public var onProgressChanged: ((Float) -> Void)?

    /// 倍速点击回调
    public var onSpeedTapped: (() -> Void)?

    // MARK: - State

    /// 是否正在播放
    public var isPlaying: Bool = false {
        didSet {
            updatePlayPauseButton()
        }
    }

    /// 当前时间
    public var currentTime: TimeInterval = 0 {
        didSet {
            updateTimeLabels()
        }
    }

    /// 总时长
    public var duration: TimeInterval = 0 {
        didSet {
            updateTimeLabels()
        }
    }

    /// 当前倍速
    public var currentSpeed: Float = 1.0 {
        didSet {
            speedButton.setTitle("\(currentSpeed)x", for: .normal)
        }
    }

    /// 是否播放完成
    public var isPlaybackEnded: Bool = false {
        didSet {
            updatePlayPauseButton()
        }
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        // 顶部工具栏
        topToolbar = UIView()
        topToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        topToolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topToolbar)

        // 关闭按钮
        closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        topToolbar.addSubview(closeButton)

        // 底部工具栏
        bottomToolbar = UIView()
        bottomToolbar.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        bottomToolbar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomToolbar)

        // 播放/暂停按钮
        playPauseButton = UIButton(type: .system)
        playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.addTarget(self, action: #selector(handlePlayPause), for: .touchUpInside)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(playPauseButton)

        // 当前时间标签
        currentTimeLabel = UILabel()
        currentTimeLabel.text = "00:00"
        currentTimeLabel.textColor = .white
        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(currentTimeLabel)

        // 进度条
        progressSlider = UISlider()
        progressSlider.minimumValue = 0
        progressSlider.maximumValue = 1
        progressSlider.value = 0
        progressSlider.minimumTrackTintColor = .white
        progressSlider.maximumTrackTintColor = .gray
        progressSlider.addTarget(self, action: #selector(handleProgressChange(_:)), for: .valueChanged)
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(progressSlider)

        // 总时长标签
        durationLabel = UILabel()
        durationLabel.text = "00:00"
        durationLabel.textColor = .white
        durationLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(durationLabel)

        // 倍速按钮
        speedButton = UIButton(type: .system)
        speedButton.setTitle("1.0x", for: .normal)
        speedButton.setTitleColor(.white, for: .normal)
        speedButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        speedButton.addTarget(self, action: #selector(handleSpeed), for: .touchUpInside)
        speedButton.translatesAutoresizingMaskIntoConstraints = false
        bottomToolbar.addSubview(speedButton)

        // 约束
        NSLayoutConstraint.activate([
            // 顶部工具栏
            topToolbar.topAnchor.constraint(equalTo: topAnchor),
            topToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            topToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            topToolbar.heightAnchor.constraint(equalToConstant: 60),

            closeButton.leadingAnchor.constraint(equalTo: topToolbar.leadingAnchor, constant: 16),
            closeButton.centerYAnchor.constraint(equalTo: topToolbar.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            // 底部工具栏
            bottomToolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomToolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomToolbar.bottomAnchor.constraint(equalTo: bottomAnchor),
            bottomToolbar.heightAnchor.constraint(equalToConstant: 60),

            // 播放按钮
            playPauseButton.leadingAnchor.constraint(equalTo: bottomToolbar.leadingAnchor, constant: 16),
            playPauseButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 44),
            playPauseButton.heightAnchor.constraint(equalToConstant: 44),

            // 当前时间
            currentTimeLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
            currentTimeLabel.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            currentTimeLabel.widthAnchor.constraint(equalToConstant: 45),

            // 进度条
            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
            progressSlider.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),

            // 总时长
            durationLabel.leadingAnchor.constraint(equalTo: progressSlider.trailingAnchor, constant: 8),
            durationLabel.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            durationLabel.widthAnchor.constraint(equalToConstant: 45),

            // 倍速按钮
            speedButton.leadingAnchor.constraint(equalTo: durationLabel.trailingAnchor, constant: 8),
            speedButton.trailingAnchor.constraint(equalTo: bottomToolbar.trailingAnchor, constant: -16),
            speedButton.centerYAnchor.constraint(equalTo: bottomToolbar.centerYAnchor),
            speedButton.widthAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func handleClose() {
        onCloseTapped?()
    }

    @objc private func handlePlayPause() {
        onPlayPauseTapped?()
    }

    @objc private func handleProgressChange(_ sender: UISlider) {
        onProgressChanged?(sender.value)
    }

    @objc private func handleSpeed() {
        onSpeedTapped?()
    }

    // MARK: - Updates

    private func updatePlayPauseButton() {
        let imageName: String
        if isPlaybackEnded {
            imageName = "arrow.clockwise"  // 重播图标
        } else if isPlaying {
            imageName = "pause.fill"
        } else {
            imageName = "play.fill"
        }
        playPauseButton.setImage(UIImage(systemName: imageName), for: .normal)
    }

    private func updateTimeLabels() {
        currentTimeLabel.text = formatTime(currentTime)
        durationLabel.text = formatTime(duration)

        if duration > 0 {
            progressSlider.value = Float(currentTime / duration)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Hit Test

    /// 只在工具栏区域拦截触摸，中间区域穿透
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 检查顶部工具栏
        let topToolbarPoint = convert(point, to: topToolbar)
        if topToolbar.bounds.contains(topToolbarPoint) {
            return topToolbar.hitTest(topToolbarPoint, with: event)
        }

        // 检查底部工具栏
        let bottomToolbarPoint = convert(point, to: bottomToolbar)
        if bottomToolbar.bounds.contains(bottomToolbarPoint) {
            return bottomToolbar.hitTest(bottomToolbarPoint, with: event)
        }

        // 中间区域不拦截触摸，返回 nil 让触摸穿透
        return nil
    }

    // MARK: - Public

    /// 设置进度（不触发回调）
    public func setProgress(_ progress: Float, animated: Bool = false) {
        if animated {
            progressSlider.setValue(progress, animated: true)
        } else {
            progressSlider.value = progress
        }
    }
}

// MARK: - 全屏容器视图

/// 全屏容器视图，简化版视图层级管理
public class PlayerFullScreenContainerView: UIView {

    // MARK: - Properties

    /// 播控视图
    public private(set) var controlView: PlayerFullScreenControlView!

    /// 播放器内容视图
    public private(set) var contentView: UIView?

    /// 视频原始尺寸（用于计算宽高比）
    public var videoSize: CGSize = .zero

    /// 是否显示播控
    public var showControl: Bool = true {
        didSet {
            controlView.isHidden = !showControl
        }
    }

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .black
        clipsToBounds = true

        // 创建播控视图
        controlView = PlayerFullScreenControlView(frame: bounds)
        controlView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(controlView)

        NSLayoutConstraint.activate([
            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.leadingAnchor.constraint(equalTo: leadingAnchor),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    public func setContentView(_ view: UIView) {
        contentView?.removeFromSuperview()
        contentView = view
        if let content = contentView {
            // 保持 frame 布局模式
            content.translatesAutoresizingMaskIntoConstraints = true
            content.autoresizingMask = []
            // 插入到播控视图下面
            insertSubview(content, belowSubview: controlView)
            updateContentViewFrame()
        }
    }

    public func updateContentViewFrame() {
        guard let content = contentView else { return }
        let containerSize = bounds.size
        guard containerSize.width > 0 && containerSize.height > 0 else { return }

        let targetRect: CGRect
        if videoSize.width > 0 && videoSize.height > 0 {
            targetRect = calculateAspectFitRect(videoSize: videoSize, containerSize: containerSize)
        } else {
            targetRect = CGRect(origin: .zero, size: containerSize)
        }

        content.frame = targetRect
    }

    /// 计算 aspectFit 矩形
    private func calculateAspectFitRect(videoSize: CGSize, containerSize: CGSize) -> CGRect {
        let videoAspect = videoSize.width / videoSize.height
        let containerAspect = containerSize.width / containerSize.height

        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if videoAspect > containerAspect {
            // 视频更宽，按宽度适配
            targetWidth = containerSize.width
            targetHeight = containerSize.width / videoAspect
        } else {
            // 视频更高，按高度适配
            targetHeight = containerSize.height
            targetWidth = containerSize.height * videoAspect
        }

        // 居中
        let x = (containerSize.width - targetWidth) / 2
        let y = (containerSize.height - targetHeight) / 2

        return CGRect(x: x, y: y, width: targetWidth, height: targetHeight)
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 每次布局都强制修正 contentView 的 frame，确保居中
        updateContentViewFrame()
    }
}

// MARK: - FullScreen Plugin

/**
 * 全屏播放插件
 */
@MainActor
public final class PlayerFullScreenPlugin: BasePlugin, PlayerFullScreenService {

    public typealias ConfigModelType = PlayerFullScreenConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?
    @PlayerPlugin private var processService: PlayerProcessService?
    @PlayerPlugin private var speedService: PlayerSpeedService?
    @PlayerPlugin private var dataService: PlayerDataService?

    private var _fullScreenState: PlayerFullScreenState = .normal
    private var _supportedOrientation: PlayerFullScreenOrientation = .auto

    /// 全屏窗口
    private var fullScreenWindow: UIWindow?
    /// 全屏容器视图
    private var fullScreenContainerView: PlayerFullScreenContainerView?
    /// 原始父视图
    private var originalSuperview: UIView?
    /// 原始 frame
    private var originalFrame: CGRect = .zero
    /// 原始 transform
    private var originalTransform: CGAffineTransform = .identity
    /// 原始 autoresizingMask
    private var originalAutoresizingMask: UIView.AutoresizingMask = []

    /// 进度更新观察者
    private var progressObserver: AnyObject?

    // MARK: - PlayerFullScreenService

    public var fullScreenState: PlayerFullScreenState {
        get { _fullScreenState }
        set {
            guard _fullScreenState != newValue else { return }
            _fullScreenState = newValue
            context?.post(.playerFullScreenStateChanged, object: _fullScreenState, sender: self)
        }
    }

    public var isFullScreen: Bool {
        return fullScreenState == .fullScreen
    }

    public var supportedOrientation: PlayerFullScreenOrientation {
        get { _supportedOrientation }
        set { _supportedOrientation = newValue }
    }

    // MARK: - Plugin Lifecycle

    public required init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerFullScreenConfigModel else { return }
        supportedOrientation = config.supportedOrientation
    }

    // MARK: - Methods

    public func enterFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        guard fullScreenState != .fullScreen,
              let playerView = engineService?.playerView else {
            return
        }

        fullScreenState = .transitioning
        context?.post(.playerWillEnterFullScreen, sender: self)

        // 保存原始状态
        originalSuperview = playerView.superview
        originalFrame = playerView.frame
        originalTransform = playerView.transform
        originalAutoresizingMask = playerView.autoresizingMask

        // 先旋转到横屏
        rotateToLandscape()

        // 延迟创建窗口，等待旋转完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.createFullScreenWindow(with: playerView, animated: animated)
        }
    }

    public func exitFullScreen(animated: Bool = true) {
        guard fullScreenState != .normal else { return }

        fullScreenState = .transitioning
        context?.post(.playerWillExitFullScreen, sender: self)

        // 移除进度观察
        removeProgressObserver()

        guard let playerView = engineService?.playerView else {
            fullScreenState = .normal
            return
        }

        // 动画退出
        if animated {
            exitWithAnimation(playerView: playerView)
        } else {
            restorePlayerView(playerView)
            fullScreenState = .normal
            context?.post(.playerDidExitFullScreen, sender: self)
        }
    }

    public func toggleFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        if isFullScreen {
            exitFullScreen(animated: animated)
        } else {
            enterFullScreen(orientation: orientation, animated: animated)
        }
    }

    // MARK: - Private Methods

    private func createFullScreenWindow(with playerView: UIView, animated: Bool) {
        // 获取横屏尺寸
        var landscapeWidth: CGFloat
        var landscapeHeight: CGFloat

        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                // 使用 windowScene 的尺寸
                let screenSize = windowScene.screen.bounds.size
                landscapeWidth = max(screenSize.width, screenSize.height)
                landscapeHeight = min(screenSize.width, screenSize.height)
            } else {
                let screenBounds = UIScreen.main.bounds
                landscapeWidth = max(screenBounds.width, screenBounds.height)
                landscapeHeight = min(screenBounds.width, screenBounds.height)
            }
        } else {
            let screenBounds = UIScreen.main.bounds
            landscapeWidth = max(screenBounds.width, screenBounds.height)
            landscapeHeight = min(screenBounds.width, screenBounds.height)
        }

        let landscapeFrame = CGRect(x: 0, y: 0, width: landscapeWidth, height: landscapeHeight)

        let window: UIWindow

        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first ?? UIApplication.shared.windows.first?.windowScene

            if let scene = scene {
                window = UIWindow(windowScene: scene)
            } else {
                window = UIWindow(frame: landscapeFrame)
            }
        } else {
            window = UIWindow(frame: landscapeFrame)
        }

        window.windowLevel = .statusBar + 1
        window.backgroundColor = .black
        window.frame = landscapeFrame

        // 创建容器视图
        let containerView = PlayerFullScreenContainerView(frame: landscapeFrame)
        containerView.backgroundColor = .black

        // 设置视频尺寸（用于计算 aspectFit）
        var videoSize = CGSize.zero
        if let dataService = dataService,
           dataService.dataModel.videoWidth > 0,
           dataService.dataModel.videoHeight > 0 {
            videoSize = CGSize(
                width: dataService.dataModel.videoWidth,
                height: dataService.dataModel.videoHeight
            )
        } else if let playerItem = engineService?.avPlayer?.currentItem {
            // 从 AVPlayerItem 获取视频尺寸
            let tracks = playerItem.asset.tracks(withMediaType: AVMediaType.video)
            if let videoTrack = tracks.first {
                let naturalSize = videoTrack.naturalSize
                let transform = videoTrack.preferredTransform
                videoSize = naturalSize.applying(transform)
                // 如果 transform 导致宽高互换，需要调整
                if videoSize.width < 0 { videoSize.width = -videoSize.width }
                if videoSize.height < 0 { videoSize.height = -videoSize.height }
            }

            // 如果还是 zero，尝试 presentationSize
            if videoSize == .zero {
                let presentationSize = playerItem.presentationSize
                if presentationSize.width > 0, presentationSize.height > 0 {
                    videoSize = presentationSize
                }
            }
        }

        containerView.videoSize = videoSize

        self.fullScreenContainerView = containerView

        // 配置播控回调
        setupControlViewCallbacks(containerView.controlView)

        // 移动播放器视图（先移除）
        playerView.removeFromSuperview()
        playerView.transform = .identity

        // 先把容器加到 window，触发 AutoLayout 解算
        window.addSubview(containerView)

        // 显示窗口
        window.makeKeyAndVisible()
        self.fullScreenWindow = window

        // 先让 containerView 完成一轮布局
        containerView.setNeedsLayout()
        containerView.layoutIfNeeded()

        // 现在设置 contentView
        containerView.setContentView(playerView)

        // 更新播控状态
        updateControlViewState()

        // 添加进度观察
        addProgressObserver()

        if animated {
            // 入场动画
            containerView.alpha = 0
            UIView.animate(withDuration: 0.3, animations: {
                containerView.alpha = 1
            }, completion: { _ in
                self.fullScreenState = .fullScreen
                self.context?.post(.playerDidEnterFullScreen, sender: self)
            })
        } else {
            fullScreenState = .fullScreen
            context?.post(.playerDidEnterFullScreen, sender: self)
        }
    }

    private func setupControlViewCallbacks(_ controlView: PlayerFullScreenControlView) {
        // 关闭按钮
        controlView.onCloseTapped = { [weak self] in
            self?.exitFullScreen(animated: true)
        }

        // 播放/暂停
        controlView.onPlayPauseTapped = { [weak self] in
            guard let self = self else { return }
            // 如果播放完成，重播
            if controlView.isPlaybackEnded {
                self.engineService?.seek(to: 0)
                controlView.isPlaybackEnded = false
            }
            if self.engineService?.playbackState == .playing {
                self.engineService?.pause()
            } else {
                self.engineService?.play()
            }
        }

        // 进度改变
        controlView.onProgressChanged = { [weak self] progress in
            guard let self = self, let duration = self.engineService?.duration, duration > 0 else { return }
            let targetTime = duration * TimeInterval(progress)
            self.engineService?.seek(to: targetTime)
        }

        // 倍速
        controlView.onSpeedTapped = { [weak self] in
            guard let self = self else { return }
            // 循环切换倍速: 1.0 -> 1.5 -> 2.0 -> 0.5 -> 1.0
            let speeds: [Float] = [1.0, 1.5, 2.0, 0.5]
            let currentSpeed = self.speedService?.currentSpeed ?? 1.0
            if let currentIndex = speeds.firstIndex(of: currentSpeed) {
                let nextIndex = (currentIndex + 1) % speeds.count
                self.speedService?.setSpeed(speeds[nextIndex])
            } else {
                self.speedService?.setSpeed(1.5)
            }
            self.updateControlViewState()
        }
    }

    private func updateControlViewState() {
        guard let controlView = fullScreenContainerView?.controlView else { return }

        controlView.isPlaying = engineService?.playbackState == .playing
        controlView.currentTime = engineService?.currentTime ?? 0
        controlView.duration = engineService?.duration ?? 0
        controlView.currentSpeed = speedService?.currentSpeed ?? 1.0
    }

    private func addProgressObserver() {
        guard let processService = processService else { return }

        processService.observeProgress { [weak self] progress, currentTime in
            guard let self = self else { return }
            self.fullScreenContainerView?.controlView.currentTime = currentTime
            self.fullScreenContainerView?.controlView.duration = self.engineService?.duration ?? 0
            self.fullScreenContainerView?.controlView.isPlaying = self.engineService?.playbackState == .playing
        }

        // 监听播放完成事件
        context?.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            self?.fullScreenContainerView?.controlView.isPlaybackEnded = true
        }
    }

    private func removeProgressObserver() {
        processService?.removeProgressObserver(progressObserver)
        progressObserver = nil
    }

    private func rotateToLandscape() {
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { _ in }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func rotateToPortrait() {
        if #available(iOS 16.0, *) {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first else { return }
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) { _ in }
        } else {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }

    private func exitWithAnimation(playerView: UIView) {
        guard let containerView = fullScreenContainerView else {
            restorePlayerView(playerView)
            fullScreenState = .normal
            context?.post(.playerDidExitFullScreen, sender: self)
            return
        }

        UIView.animate(withDuration: 0.3, animations: {
            containerView.alpha = 0
        }, completion: { _ in
            self.restorePlayerView(playerView)
            self.rotateToPortrait()
            self.fullScreenState = .normal
            self.context?.post(.playerDidExitFullScreen, sender: self)
        })
    }

    private func restorePlayerView(_ playerView: UIView) {
        playerView.removeFromSuperview()

        // 恢复为 frame 布局模式
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.transform = originalTransform
        playerView.frame = originalFrame
        playerView.autoresizingMask = originalAutoresizingMask

        if let superview = originalSuperview {
            superview.addSubview(playerView)
        }

        fullScreenWindow?.isHidden = true
        fullScreenWindow = nil
        fullScreenContainerView = nil
    }
}
