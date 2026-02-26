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
import PlayerKit

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
 *
 * 使用 View Reparent + CGAffineTransform 旋转动画实现丝滑全屏转场：
 * - 视频图层不重建，playerView 仅换父视图，AVPlayer 渲染层从未断开
 * - GPU 加速的仿射变换，不触发离屏渲染
 * - 0.3s EaseInOut 动画曲线
 * - 坐标系精确转换，保证起始位置与原始位置完全重合
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
    /// 全屏播控视图
    private var fullScreenControlView: PlayerFullScreenControlView?
    /// 黑色背景视图
    private var backgroundView: UIView?
    /// 原始父视图
    private var originalSuperview: UIView?
    /// 原始 frame
    private var originalFrame: CGRect = .zero
    /// 原始 transform
    private var originalTransform: CGAffineTransform = .identity
    /// 原始 autoresizingMask
    private var originalAutoresizingMask: UIView.AutoresizingMask = []
    /// 原始 translatesAutoresizingMaskIntoConstraints
    private var originalTranslatesAutoresizingMaskIntoConstraints: Bool = true
    /// playerView 在 window 坐标系中的原始位置（用于退出动画的目标位置）
    private var originalFrameInWindow: CGRect = .zero

    /// 进度更新观察者 token
    private var progressObserverToken: String?

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

    // MARK: - Enter / Exit

    public func enterFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        guard fullScreenState != .fullScreen,
              let playerView = engineService?.playerView else {
            return
        }

        fullScreenState = .transitioning
        context?.post(.playerWillEnterFullScreen, sender: self)

        // 1. 保存原始状态
        originalSuperview = playerView.superview
        originalFrame = playerView.frame
        originalTransform = playerView.transform
        originalAutoresizingMask = playerView.autoresizingMask
        originalTranslatesAutoresizingMaskIntoConstraints = playerView.translatesAutoresizingMaskIntoConstraints

        // 2. 精确坐标转换：计算 playerView 在 window 坐标系中的位置
        originalFrameInWindow = playerView.superview?.convert(playerView.frame, to: nil) ?? playerView.frame

        // 3. 屏幕尺寸（竖屏状态）
        let screenBounds = UIScreen.main.bounds
        let landscapeWidth = max(screenBounds.width, screenBounds.height)
        let landscapeHeight = min(screenBounds.width, screenBounds.height)

        // 4. 获取视频尺寸，计算横屏下的 aspect-fit 尺寸
        let videoSize = resolveVideoSize()
        let landscapeContainer = CGSize(width: landscapeWidth, height: landscapeHeight)
        let targetSize: CGSize
        if videoSize.width > 0, videoSize.height > 0 {
            targetSize = aspectFitSize(videoSize: videoSize, containerSize: landscapeContainer)
        } else {
            targetSize = landscapeContainer
        }

        // 5. 创建全屏 window（竖屏尺寸，不旋转设备方向）
        let window = makeWindow(frame: screenBounds)
        window.backgroundColor = .clear

        // 6. 黑色背景（跟随动画渐入）
        let bgView = UIView(frame: screenBounds)
        bgView.backgroundColor = .black
        bgView.alpha = 0
        window.addSubview(bgView)
        self.backgroundView = bgView

        // 7. 视图重挂载：playerView 从原始父视图移到 window
        //    不销毁、不重建，AVPlayer 渲染层从未断开
        playerView.removeFromSuperview()
        playerView.translatesAutoresizingMaskIntoConstraints = true
        playerView.autoresizingMask = []
        playerView.transform = .identity
        playerView.frame = originalFrameInWindow
        window.addSubview(playerView)

        window.makeKeyAndVisible()
        self.fullScreenWindow = window

        // 8. 目标状态
        let targetCenter = CGPoint(x: screenBounds.width / 2, y: screenBounds.height / 2)
        let angle: CGFloat = .pi / 2

        // 9. 执行 0.3s EaseInOut 动画：旋转 + 缩放同步
        //    使用 bounds/center/transform 而非 frame，让 UIKit 同步插值旋转和缩放
        let animateBlock = {
            playerView.bounds = CGRect(origin: .zero, size: targetSize)
            playerView.center = targetCenter
            playerView.transform = CGAffineTransform(rotationAngle: angle)
            bgView.alpha = 1
        }

        let completionBlock: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.setupFullScreenOverlay(in: window, landscapeWidth: landscapeWidth, landscapeHeight: landscapeHeight)
            self.fullScreenState = .fullScreen
            self.context?.post(.playerDidEnterFullScreen, sender: self)
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: animateBlock) { _ in
                completionBlock()
            }
        } else {
            animateBlock()
            completionBlock()
        }
    }

    public func exitFullScreen(animated: Bool = true) {
        guard fullScreenState != .normal else { return }

        fullScreenState = .transitioning
        context?.post(.playerWillExitFullScreen, sender: self)

        removeProgressObserver()

        guard let playerView = engineService?.playerView else {
            fullScreenState = .normal
            return
        }

        // 移除播控覆盖层
        fullScreenControlView?.removeFromSuperview()
        fullScreenControlView = nil

        // 反向动画：缩放 + 旋转同步恢复，背景渐出
        let animateBlock = {
            playerView.bounds = CGRect(origin: .zero, size: self.originalFrameInWindow.size)
            playerView.center = CGPoint(x: self.originalFrameInWindow.midX, y: self.originalFrameInWindow.midY)
            playerView.transform = .identity
            self.backgroundView?.alpha = 0
        }

        let completionBlock: () -> Void = { [weak self] in
            guard let self = self else { return }
            self.restorePlayerView(playerView)
            self.fullScreenState = .normal
            self.context?.post(.playerDidExitFullScreen, sender: self)
        }

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: animateBlock) { _ in
                completionBlock()
            }
        } else {
            animateBlock()
            completionBlock()
        }
    }

    public func toggleFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        if isFullScreen {
            exitFullScreen(animated: animated)
        } else {
            enterFullScreen(orientation: orientation, animated: animated)
        }
    }

    // MARK: - Private

    private func makeWindow(frame: CGRect) -> UIWindow {
        if #available(iOS 13.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first {
                let w = UIWindow(windowScene: scene)
                w.frame = frame
                w.windowLevel = .statusBar + 1
                return w
            }
        }
        let w = UIWindow(frame: frame)
        w.windowLevel = .statusBar + 1
        return w
    }

    /// 动画完成后添加播控覆盖层（横屏方向，与 playerView 同角度旋转）
    private func setupFullScreenOverlay(in window: UIWindow, landscapeWidth: CGFloat, landscapeHeight: CGFloat) {
        let screenBounds = UIScreen.main.bounds

        let controlView = PlayerFullScreenControlView(
            frame: CGRect(x: 0, y: 0, width: landscapeWidth, height: landscapeHeight)
        )
        controlView.center = CGPoint(x: screenBounds.width / 2, y: screenBounds.height / 2)
        controlView.transform = CGAffineTransform(rotationAngle: .pi / 2)
        window.addSubview(controlView)

        self.fullScreenControlView = controlView

        setupControlViewCallbacks(controlView)
        updateControlViewState()
        addProgressObserver()
    }

    private func setupControlViewCallbacks(_ controlView: PlayerFullScreenControlView) {
        controlView.onCloseTapped = { [weak self] in
            self?.exitFullScreen(animated: true)
        }

        controlView.onPlayPauseTapped = { [weak self] in
            guard let self = self else { return }
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

        controlView.onProgressChanged = { [weak self] progress in
            guard let self = self, let duration = self.engineService?.duration, duration > 0 else { return }
            let targetTime = duration * TimeInterval(progress)
            self.engineService?.seek(to: targetTime)
        }

        controlView.onSpeedTapped = { [weak self] in
            guard let self = self else { return }
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
        guard let controlView = fullScreenControlView else { return }

        controlView.isPlaying = engineService?.playbackState == .playing
        controlView.currentTime = engineService?.currentTime ?? 0
        controlView.duration = engineService?.duration ?? 0
        controlView.currentSpeed = speedService?.currentSpeed ?? 1.0
    }

    private func addProgressObserver() {
        guard let processService = processService else { return }

        progressObserverToken = processService.observeProgress { [weak self] progress, currentTime in
            guard let self = self else { return }
            self.fullScreenControlView?.currentTime = currentTime
            self.fullScreenControlView?.duration = self.engineService?.duration ?? 0
            self.fullScreenControlView?.isPlaying = self.engineService?.playbackState == .playing
        }

        context?.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            self?.fullScreenControlView?.isPlaybackEnded = true
        }
    }

    /// 获取视频原始尺寸（优先 dataModel，兜底 AVPlayerItem）
    private func resolveVideoSize() -> CGSize {
        if let ds = dataService,
           ds.dataModel.videoWidth > 0,
           ds.dataModel.videoHeight > 0 {
            return CGSize(width: ds.dataModel.videoWidth, height: ds.dataModel.videoHeight)
        }

        if let item = engineService?.avPlayer?.currentItem {
            let tracks = item.asset.tracks(withMediaType: .video)
            if let track = tracks.first {
                var size = track.naturalSize.applying(track.preferredTransform)
                if size.width < 0 { size.width = -size.width }
                if size.height < 0 { size.height = -size.height }
                if size.width > 0, size.height > 0 { return size }
            }

            let ps = item.presentationSize
            if ps.width > 0, ps.height > 0 { return ps }
        }

        return .zero
    }

    /// 计算视频在容器中的 aspect-fit 尺寸
    private func aspectFitSize(videoSize: CGSize, containerSize: CGSize) -> CGSize {
        let videoAspect = videoSize.width / videoSize.height
        let containerAspect = containerSize.width / containerSize.height

        if videoAspect > containerAspect {
            // 视频更宽，按宽度适配
            return CGSize(width: containerSize.width, height: containerSize.width / videoAspect)
        } else {
            // 视频更高，按高度适配
            return CGSize(width: containerSize.height * videoAspect, height: containerSize.height)
        }
    }

    private func removeProgressObserver() {
        if let token = progressObserverToken {
            processService?.removeProgressObserver(token: token)
            progressObserverToken = nil
        }
    }

    /// 将 playerView 恢复到原始父视图
    private func restorePlayerView(_ playerView: UIView) {
        playerView.removeFromSuperview()

        playerView.translatesAutoresizingMaskIntoConstraints = originalTranslatesAutoresizingMaskIntoConstraints
        playerView.transform = originalTransform
        playerView.frame = originalFrame
        playerView.autoresizingMask = originalAutoresizingMask

        if let superview = originalSuperview {
            superview.addSubview(playerView)

            if !originalTranslatesAutoresizingMaskIntoConstraints {
                playerView.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                playerView.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
                playerView.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
                playerView.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            }
        }

        backgroundView = nil
        fullScreenWindow?.isHidden = true
        fullScreenWindow = nil
    }
}
