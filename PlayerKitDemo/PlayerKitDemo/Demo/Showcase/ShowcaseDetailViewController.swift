import UIKit
import AVFoundation
import PlayerKit

@MainActor
final class ShowcaseDetailViewController: UIViewController, ShowcaseGestureDelegate {

    var video: ShowcaseVideo?
    var videoIndex: Int = 0
    var player: Player?
    
    var allVideos: [ShowcaseVideo] = []
    var onWillDismiss: (() -> Void)?
    var onDismiss: (() -> Void)?

    var playerContainerView: UIView? { _playerContainer }

    private let _playerContainer = UIView()
    private let detailSceneContext = ShowcaseDetailSceneContext()

    private let controlOverlay = UIView()
    private let playPauseButton = UIButton(type: .system)
    private let progressSlider = UISlider()
    private let currentTimeLabel = UILabel()
    private let durationLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let speedButton = UIButton(type: .system)
    private let muteButton = UIButton(type: .system)
    private let fullScreenButton = UIButton(type: .system)
    private let loopButton = UIButton(type: .system)
    private let snapshotButton = UIButton(type: .system)
    private let subtitleButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let debugButton = UIButton(type: .system)
    private let speedIndicatorLabel = UILabel()
    private let gestureHintLabel = UILabel()

    private var controlVisible = true

    private var singleTapHandler: ShowcaseSingleTapHandler!
    private var doubleTapHandler: ShowcaseDoubleTapHandler!
    private var panHandler: ShowcasePanHandler!
    private var longPressHandler: ShowcaseLongPressHandler!
    private var pinchHandler: ShowcasePinchHandler!

    private var detailControl: ShowcaseDetailControlService?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupPlayerContainer()
        setupCoverImage()
        setupControlOverlay()
        setupDetailControl()
        setupGestureHandlers()

        attachPlayer()
        detailControl?.scheduleControlHide()
    }

    override var prefersStatusBarHidden: Bool { true }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed || isMovingFromParent {
            performCleanupIfNeeded()
        }
    }

    private var didCleanup = false

    private func performCleanupIfNeeded() {
        guard !didCleanup else { return }
        didCleanup = true
        removeGestureHandlers()
        detailControl?.teardown()
        detailControl = nil
        detailSceneContext.removePlayer()
        onWillDismiss?()
        onWillDismiss = nil
        onDismiss = nil
        player = nil
    }

    private func removeGestureHandlers() {
        guard let gestureService = detailSceneContext.gestureService else { return }
        if let h = singleTapHandler { gestureService.removeHandler(h) }
        if let h = doubleTapHandler { gestureService.removeHandler(h) }
        if let h = panHandler { gestureService.removeHandler(h) }
        if let h = longPressHandler { gestureService.removeHandler(h) }
        if let h = pinchHandler { gestureService.removeHandler(h) }
    }

    // MARK: - Register & Setup Detail Control Plugin

    private func setupDetailControl() {
        guard let player = player else { return }
        detailSceneContext.addPlayer(player)

        detailControl = detailSceneContext.detailControlService
        guard let video = video else { return }
        let controlConfig = ShowcaseDetailControlConfigModel(
            video: video,
            allVideos: allVideos,
            videoIndex: videoIndex,
            gestureView: view
        )
        detailSceneContext.context.configPlugin(serviceProtocol: ShowcaseDetailControlService.self, withModel: controlConfig)

        detailControl?.onPlaybackStateChanged = { [weak self] isPlaying in
            guard let self = self else { return }
            let icon = isPlaying ? "pause.fill" : "play.fill"
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            self.playPauseButton.setImage(UIImage(systemName: icon, withConfiguration: config), for: .normal)
        }

        detailControl?.onProgressUpdate = { [weak self] progress, timeStr, durationStr in
            guard let self = self else { return }
            self.progressSlider.value = progress
            self.currentTimeLabel.text = timeStr
            self.durationLabel.text = durationStr
        }

        detailControl?.onControlShouldShow = { [weak self] show in
            self?.showControlOverlay(show)
        }
    }

    private func setupGestureHandlers() {
        guard let gestureService = detailSceneContext.gestureService else { return }

        singleTapHandler = ShowcaseSingleTapHandler()
        singleTapHandler.delegate = self
        gestureService.addHandler(singleTapHandler)

        doubleTapHandler = ShowcaseDoubleTapHandler()
        doubleTapHandler.delegate = self
        gestureService.addHandler(doubleTapHandler)

        panHandler = ShowcasePanHandler()
        panHandler.delegate = self
        gestureService.addHandler(panHandler)

        longPressHandler = ShowcaseLongPressHandler()
        longPressHandler.delegate = self
        gestureService.addHandler(longPressHandler)

        pinchHandler = ShowcasePinchHandler()
        pinchHandler.delegate = self
        gestureService.addHandler(pinchHandler)
    }

    // MARK: - Setup Player Container

    private func setupPlayerContainer() {
        _playerContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_playerContainer)
        NSLayoutConstraint.activate([
            _playerContainer.topAnchor.constraint(equalTo: view.topAnchor),
            _playerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _playerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _playerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupCoverImage() {
    }

    // MARK: - Control Overlay

    private func setupControlOverlay() {
        controlOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controlOverlay)
        NSLayoutConstraint.activate([
            controlOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            controlOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            controlOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            controlOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let topGradient = UIView()
        topGradient.translatesAutoresizingMaskIntoConstraints = false
        controlOverlay.addSubview(topGradient)
        topGradient.backgroundColor = UIColor.black.withAlphaComponent(0.3)

        let bottomBar = UIView()
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        controlOverlay.addSubview(bottomBar)
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)

        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: iconConfig), for: .normal)
        closeButton.tintColor = .white
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        controlOverlay.addSubview(closeButton)

        let titleLabel = UILabel()
        titleLabel.text = video?.title ?? ""
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        controlOverlay.addSubview(titleLabel)

        debugButton.setImage(UIImage(systemName: "ladybug", withConfiguration: iconConfig), for: .normal)
        debugButton.tintColor = .white
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        debugButton.addTarget(self, action: #selector(debugTapped), for: .touchUpInside)
        controlOverlay.addSubview(debugButton)

        playPauseButton.setImage(UIImage(systemName: "pause.fill", withConfiguration: largeConfig), for: .normal)
        playPauseButton.tintColor = .white
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        controlOverlay.addSubview(playPauseButton)

        currentTimeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        currentTimeLabel.textColor = .white
        currentTimeLabel.text = "00:00"
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(currentTimeLabel)

        durationLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        durationLabel.textColor = .white.withAlphaComponent(0.7)
        durationLabel.text = "00:00"
        durationLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(durationLabel)

        progressSlider.minimumTrackTintColor = .white
        progressSlider.maximumTrackTintColor = .white.withAlphaComponent(0.3)
        progressSlider.translatesAutoresizingMaskIntoConstraints = false
        progressSlider.addTarget(self, action: #selector(sliderBegan(_:)), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(sliderEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        bottomBar.addSubview(progressSlider)

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(buttonStack)

        for (btn, icon, action) in [
            (speedButton, "gauge.with.dots.needle.33percent", #selector(speedTapped)),
            (muteButton, "speaker.wave.2.fill", #selector(muteTapped)),
            (loopButton, "repeat", #selector(loopTapped)),
            (snapshotButton, "camera.fill", #selector(snapshotTapped)),
            (fullScreenButton, "arrow.up.left.and.arrow.down.right", #selector(fullScreenTapped)),
            (settingsButton, "gearshape", #selector(settingsTapped)),
        ] as [(UIButton, String, Selector)] {
            btn.setImage(UIImage(systemName: icon, withConfiguration: iconConfig), for: .normal)
            btn.tintColor = .white
            btn.addTarget(self, action: action, for: .touchUpInside)
            buttonStack.addArrangedSubview(btn)
        }

        speedIndicatorLabel.font = .systemFont(ofSize: 14, weight: .bold)
        speedIndicatorLabel.textColor = .white
        speedIndicatorLabel.textAlignment = .center
        speedIndicatorLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        speedIndicatorLabel.layer.cornerRadius = 6
        speedIndicatorLabel.clipsToBounds = true
        speedIndicatorLabel.isHidden = true
        speedIndicatorLabel.translatesAutoresizingMaskIntoConstraints = false
        controlOverlay.addSubview(speedIndicatorLabel)

        gestureHintLabel.font = .systemFont(ofSize: 12, weight: .medium)
        gestureHintLabel.textColor = .white.withAlphaComponent(0.7)
        gestureHintLabel.textAlignment = .center
        gestureHintLabel.isHidden = true
        gestureHintLabel.translatesAutoresizingMaskIntoConstraints = false
        controlOverlay.addSubview(gestureHintLabel)

        NSLayoutConstraint.activate([
            topGradient.topAnchor.constraint(equalTo: controlOverlay.topAnchor),
            topGradient.leadingAnchor.constraint(equalTo: controlOverlay.leadingAnchor),
            topGradient.trailingAnchor.constraint(equalTo: controlOverlay.trailingAnchor),
            topGradient.heightAnchor.constraint(equalToConstant: 100),

            closeButton.topAnchor.constraint(equalTo: controlOverlay.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: controlOverlay.leadingAnchor, constant: 16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: closeButton.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: debugButton.leadingAnchor, constant: -8),

            debugButton.topAnchor.constraint(equalTo: controlOverlay.safeAreaLayoutGuide.topAnchor, constant: 8),
            debugButton.trailingAnchor.constraint(equalTo: controlOverlay.trailingAnchor, constant: -16),
            debugButton.widthAnchor.constraint(equalToConstant: 36),
            debugButton.heightAnchor.constraint(equalToConstant: 36),

            playPauseButton.centerXAnchor.constraint(equalTo: controlOverlay.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: controlOverlay.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 60),
            playPauseButton.heightAnchor.constraint(equalToConstant: 60),

            bottomBar.leadingAnchor.constraint(equalTo: controlOverlay.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: controlOverlay.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: controlOverlay.bottomAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 100),

            currentTimeLabel.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 16),
            currentTimeLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),

            durationLabel.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -16),
            durationLabel.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 12),

            progressSlider.leadingAnchor.constraint(equalTo: currentTimeLabel.trailingAnchor, constant: 8),
            progressSlider.trailingAnchor.constraint(equalTo: durationLabel.leadingAnchor, constant: -8),
            progressSlider.centerYAnchor.constraint(equalTo: currentTimeLabel.centerYAnchor),

            buttonStack.centerXAnchor.constraint(equalTo: bottomBar.centerXAnchor),
            buttonStack.topAnchor.constraint(equalTo: progressSlider.bottomAnchor, constant: 8),

            speedIndicatorLabel.centerXAnchor.constraint(equalTo: controlOverlay.centerXAnchor),
            speedIndicatorLabel.topAnchor.constraint(equalTo: controlOverlay.safeAreaLayoutGuide.topAnchor, constant: 60),
            speedIndicatorLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            speedIndicatorLabel.heightAnchor.constraint(equalToConstant: 32),

            gestureHintLabel.centerXAnchor.constraint(equalTo: controlOverlay.centerXAnchor),
            gestureHintLabel.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -12),
        ])
    }

    // MARK: - Attach / Detach

    private func attachPlayer() {
        guard let player = player else { return }
        guard let pv = player.context.service(PlayerEngineCoreService.self)?.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        _playerContainer.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: _playerContainer.topAnchor),
            pv.leadingAnchor.constraint(equalTo: _playerContainer.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: _playerContainer.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: _playerContainer.bottomAnchor)
        ])
    }

    // MARK: - Control Actions

    @objc private func closeTapped() {
        performCleanupIfNeeded()
        dismiss(animated: true)
    }

    @objc private func playPauseTapped() {
        detailControl?.togglePlayPause()
    }

    @objc private func speedTapped() {
        let speed = detailControl?.cycleSpeed() ?? 1.0
        speedButton.setTitle("\(speed)x", for: .normal)
    }

    @objc private func muteTapped() {
        let isMuted = detailControl?.toggleMute() ?? false
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let icon = isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill"
        muteButton.setImage(UIImage(systemName: icon, withConfiguration: iconConfig), for: .normal)
    }

    @objc private func loopTapped() {
        let isLooping = detailControl?.toggleLoop() ?? false
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let icon = isLooping ? "repeat.1" : "repeat"
        loopButton.setImage(UIImage(systemName: icon, withConfiguration: iconConfig), for: .normal)
    }

    @objc private func snapshotTapped() {
        detailControl?.captureSnapshot { [weak self] image in
            guard let self = self, let image = image else { return }

            let preview = UIImageView(image: image)
            preview.contentMode = .scaleAspectFit
            preview.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            preview.frame = self.view.bounds
            preview.isUserInteractionEnabled = true
            preview.alpha = 0
            self.view.addSubview(preview)

            let tap = UITapGestureRecognizer(target: self, action: #selector(self.dismissSnapshotPreview(_:)))
            preview.addGestureRecognizer(tap)

            UIView.animate(withDuration: 0.3) { preview.alpha = 1 }
        }
    }

    @objc private func dismissSnapshotPreview(_ gr: UITapGestureRecognizer) {
        guard let preview = gr.view else { return }
        UIView.animate(withDuration: 0.3, animations: { preview.alpha = 0 }) { _ in
            preview.removeFromSuperview()
        }
    }

    @objc private func fullScreenTapped() {
        detailControl?.toggleFullScreen()
    }

    @objc private func settingsTapped() {
        showSettingsPanel()
    }

    @objc private func debugTapped() {
        detailControl?.showDebugPanel()
    }

    // MARK: - Settings Panel

    private func showSettingsPanel() {
        let panel = UIView()
        panel.backgroundColor = UIColor(white: 0.15, alpha: 1)
        panel.layer.cornerRadius = 16
        panel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(scrollView)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        let headerLabel = UILabel()
        headerLabel.text = "Settings & Info"
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = .white
        stack.addArrangedSubview(headerLabel)

        let sep1 = makeSeparator()
        stack.addArrangedSubview(sep1)

        let trackerLabel = UILabel()
        trackerLabel.text = "Tracker Events"
        trackerLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        trackerLabel.textColor = .white
        stack.addArrangedSubview(trackerLabel)

        let trackerInfo = UILabel()
        trackerInfo.text = "detail_enter, playback_finish, snapshot, speed_change, detail_exit"
        trackerInfo.font = .systemFont(ofSize: 12)
        trackerInfo.textColor = .white.withAlphaComponent(0.6)
        trackerInfo.numberOfLines = 0
        stack.addArrangedSubview(trackerInfo)

        let sep2 = makeSeparator()
        stack.addArrangedSubview(sep2)

        addInfoRow(to: stack, title: "Context Name", value: detailControl?.contextName() ?? "N/A")
        addInfoRow(to: stack, title: "Video ID", value: video?.feedId ?? "")
        addInfoRow(to: stack, title: "App Active", value: "Monitoring")

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: panel.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -20),

            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        let panelService = detailSceneContext.panelService
        panelService?.showPanel(panel as AnyObject, at: .bottom, animated: true)

        panel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(panel)

        let panelHeight: CGFloat = 380
        let panelBottomConstraint = panel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panel.heightAnchor.constraint(equalToConstant: panelHeight),
            panelBottomConstraint,
        ])

        panel.transform = CGAffineTransform(translationX: 0, y: panelHeight)
        UIView.animate(withDuration: 0.3) { panel.transform = .identity }

        let dismissTap = UITapGestureRecognizer(target: self, action: #selector(dismissSettingsPanel(_:)))
        let bgOverlay = UIView()
        bgOverlay.tag = 9999
        bgOverlay.frame = view.bounds
        bgOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        bgOverlay.addGestureRecognizer(dismissTap)
        view.insertSubview(bgOverlay, belowSubview: panel)
        panel.tag = 9998
    }

    @objc private func dismissSettingsPanel(_ gr: UITapGestureRecognizer) {
        if let overlay = view.viewWithTag(9999) {
            overlay.removeFromSuperview()
        }
        if let panel = view.viewWithTag(9998) {
            UIView.animate(withDuration: 0.3, animations: {
                panel.transform = CGAffineTransform(translationX: 0, y: 380)
            }) { _ in
                panel.removeFromSuperview()
            }
        }
    }

    private func addInfoRow(to stack: UIStackView, title: String, value: String) {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 13)
        titleLbl.textColor = .white.withAlphaComponent(0.7)

        let valueLbl = UILabel()
        valueLbl.text = value
        valueLbl.font = .monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        valueLbl.textColor = .white

        row.addArrangedSubview(titleLbl)
        row.addArrangedSubview(valueLbl)
        stack.addArrangedSubview(row)
    }

    private func makeSeparator() -> UIView {
        let sep = UIView()
        sep.backgroundColor = .white.withAlphaComponent(0.15)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return sep
    }

    // MARK: - Slider Actions

    @objc private func sliderBegan(_ slider: UISlider) {
        detailControl?.beginSliderScrub()
    }

    @objc private func sliderChanged(_ slider: UISlider) {
        if let timeStr = detailControl?.sliderChanged(to: slider.value) {
            currentTimeLabel.text = timeStr
        }
    }

    @objc private func sliderEnded(_ slider: UISlider) {
        _ = detailControl?.sliderChanged(to: slider.value)
        detailControl?.endSliderScrub()
    }

    // MARK: - Control Visibility

    private func showControlOverlay(_ show: Bool) {
        controlVisible = show
        UIView.animate(withDuration: 0.25) {
            self.controlOverlay.alpha = show ? 1 : 0
        }
        if show { detailControl?.scheduleControlHide() }
    }

    // MARK: - ShowcaseGestureDelegate

    func didSingleTap() {
        showControlOverlay(!controlVisible)
    }

    func didDoubleTap() {
        detailControl?.togglePlayPause()
    }

    func didBeginPan(direction: PlayerPanDirection) {
        detailControl?.handlePanBegin(direction: direction)
        switch direction {
        case .horizontal:
            gestureHintLabel.isHidden = false
        case .verticalLeft:
            gestureHintLabel.text = "Brightness"
            gestureHintLabel.isHidden = false
        case .verticalRight:
            gestureHintLabel.text = "Volume"
            gestureHintLabel.isHidden = false
        default:
            break
        }
    }

    func didChangePan(direction: PlayerPanDirection, delta: Float) {
        if let hint = detailControl?.handlePanChange(direction: direction, delta: delta) {
            gestureHintLabel.text = hint
        }
    }

    func didEndPan(direction: PlayerPanDirection) {
        gestureHintLabel.isHidden = true
        detailControl?.handlePanEnd(direction: direction)
    }

    func didBeginLongPress() {
        detailControl?.handleLongPressBegin()
        detailSceneContext.longPressSpeedService?.beginLongPressSpeed()
        speedIndicatorLabel.text = "  3.0x  "
        speedIndicatorLabel.isHidden = false
    }

    func didEndLongPress() {
        detailControl?.handleLongPressEnd()
        detailSceneContext.longPressSpeedService?.endLongPressSpeed()
        speedIndicatorLabel.isHidden = true
    }

    func didPinch(scale: CGFloat) {
        _ = detailControl?.handlePinch(scale: scale)
    }
}
