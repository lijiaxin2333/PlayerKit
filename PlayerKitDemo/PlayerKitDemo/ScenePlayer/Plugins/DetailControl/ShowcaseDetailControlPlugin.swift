import UIKit
import PlayerKit

@MainActor
public final class ShowcaseDetailControlPlugin: BasePlugin, ShowcaseDetailControlService {

    private var video: ShowcaseVideo?
    private var videoIndex: Int = 0

    private(set) public var isScrubbing = false
    private var previousSpeed: Float = 1.0
    private var controlHideTimer: Timer?
    private var progressObserverToken: String?

    public var onPlaybackStateChanged: ((Bool) -> Void)?
    public var onProgressUpdate: ((Float, String, String) -> Void)?
    public var onControlShouldShow: ((Bool) -> Void)?

    @PlayerPlugin private var engineService: PlayerEngineCoreService?
    @PlayerPlugin private var processService: PlayerProcessService?
    @PlayerPlugin private var speedService: PlayerSpeedService?
    @PlayerPlugin private var startTimeService: PlayerStartTimeService?
    @PlayerPlugin private var gestureService: PlayerGestureService?
    @PlayerPlugin private var tipService: PlayerTipManagerService?
    @PlayerPlugin private var finishViewService: PlayerFinishViewService?
    @PlayerPlugin private var playbackControl: PlayerPlaybackControlService?
    @PlayerPlugin private var toastService: PlayerToastService?
    @PlayerPlugin private var mediaService: PlayerMediaControlService?
    @PlayerPlugin private var snapshotService: PlayerSnapshotService?
    @PlayerPlugin private var fullScreenService: PlayerFullScreenService?
    @PlayerPlugin private var debugService: PlayerDebugService?

    public override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseDetailControlConfigModel else { return }
        guard let gestureView = model.gestureView else { return }
        self.video = model.video
        self.videoIndex = model.videoIndex

        setupGestures(gestureView: gestureView)
        setupStartTime(video: model.video)
        observeEvents()
    }

    public func teardown() {
        controlHideTimer?.invalidate()
        controlHideTimer = nil

        startTimeService?.cacheCurrentProgress()

        gestureService?.isPanEnabled = false
        gestureService?.isPinchEnabled = false
        gestureService?.gestureView = nil

        if let token = progressObserverToken {
            processService?.removeProgressObserver(token: token)
            progressObserverToken = nil
        }
        context?.removeHandlers(forObserver: self)

        onPlaybackStateChanged = nil
        onProgressUpdate = nil
        onControlShouldShow = nil
    }

    private func setupGestures(gestureView: UIView) {
        guard let gestureService = gestureService else { return }
        gestureService.gestureView = gestureView
        gestureService.isPanEnabled = true
        gestureService.isPinchEnabled = true
    }

    private func setupStartTime(video: ShowcaseVideo) {
        guard let startTimeService = startTimeService else { return }
        startTimeService.cacheProgressEnabled = true
        if let url = video.url {
            let key = url.absoluteString
            if let cached = startTimeService.cachedProgress(forKey: key) {
                startTimeService.setStartTime(cached)
            }
        }
    }

    private func observeEvents() {
        guard let ctx = context else { return }

        progressObserverToken = processService?.observeProgress { [weak self] progress, time in
            guard let self = self else { return }
            let scrubbing = self.isScrubbing || (self.processService?.isScrubbing == true)
            if !scrubbing {
                let timeStr = self.formatTime(time)
                let durationStr = self.formatTime(self.engineService?.duration ?? 0)
                self.onProgressUpdate?(Float(progress), timeStr, durationStr)
            }
        }

        ctx.add(self, event: .playerPlaybackStateChanged) { [weak self] _, _ in
            guard let self = self else { return }
            let isPlaying = self.engineService?.playbackState == .playing
            self.onPlaybackStateChanged?(isPlaying)
        }

        ctx.add(self, event: .playerPlayingStalledBegin) { [weak self] _, _ in
            self?.tipService?.showTip(.buffering, message: "Buffering...")
        }

        ctx.add(self, event: .playerPlayingStalledEnd) { [weak self] _, _ in
            self?.tipService?.hideTip(.buffering)
        }

        ctx.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            guard let self = self else { return }
            self.finishViewService?.showFinishView()
            self.onControlShouldShow?(true)
            self.startTimeService?.cacheCurrentProgress()
        }

    }

    public func togglePlayPause() {
        playbackControl?.togglePlayPause()
        scheduleControlHide()
    }

    public func cycleSpeed() -> Float {
        guard let speedService = speedService else { return 1.0 }
        let speeds: [Float] = [0.5, 1.0, 1.5, 2.0]
        let current = speedService.currentSpeed
        let nextIdx = (speeds.firstIndex(of: current) ?? 1) + 1
        let next = speeds[nextIdx % speeds.count]
        speedService.setSpeed(next)

        toastService?.showToast("Speed: \(next)x", style: .info, duration: 1.5)
        return next
    }

    public func toggleMute() -> Bool {
        mediaService?.toggleMute()
        return mediaService?.isMuted == true
    }

    public func toggleLoop() -> Bool {
        guard let engine = engineService else { return false }
        engine.isLooping.toggle()
        toastService?.showToast(engine.isLooping ? "Loop: ON" : "Loop: OFF", style: .info, duration: 1.5)
        return engine.isLooping
    }

    public func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
        snapshotService?.currentFrameImage { [weak self] image in
            guard let self = self else { completion(nil); return }
            if image != nil {
                self.toastService?.showToast("Screenshot captured!", style: .success, duration: 2.0)
            }
            completion(image)
        }
    }

    public func toggleFullScreen() {
        fullScreenService?.toggleFullScreen(orientation: .auto, animated: true)
    }

    public func showDebugPanel() {
        debugService?.isDebugEnabled = true
        debugService?.showDebugPanel()
    }

    public func beginSliderScrub() {
        isScrubbing = true
        processService?.beginScrubbing()
    }

    public func sliderChanged(to value: Float) -> String? {
        processService?.scrubbing(to: Double(value))
        if let duration = engineService?.duration {
            return formatTime(TimeInterval(value) * duration)
        }
        return nil
    }

    public func endSliderScrub() {
        processService?.endScrubbing()
        context?.add(self, event: .playerProgressEndScrubbing, option: .execOnlyOnce) { [weak self] _, _ in
            self?.isScrubbing = false
        }
    }

    public func scheduleControlHide() {
        controlHideTimer?.invalidate()
        controlHideTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.engineService?.playbackState == .playing {
                self.onControlShouldShow?(false)
            }
        }
    }

    public func contextName() -> String {
        (context as? Context)?.name ?? "N/A"
    }

    public func handlePanBegin(direction: PlayerPanDirection) {
        if direction == .horizontal {
            isScrubbing = true
            processService?.beginScrubbing()
        }
    }

    public func handlePanChange(direction: PlayerPanDirection, delta: Float) -> String? {
        switch direction {
        case .horizontal:
            let current = processService?.progress ?? 0
            let newProgress = min(1, max(0, current + Double(delta * 0.3)))
            processService?.scrubbing(to: newProgress)
            if let duration = engineService?.duration {
                return formatTime(newProgress * duration)
            }
            return nil
        case .verticalLeft:
            mediaService?.setBrightness((mediaService?.brightness ?? 0.5) + delta * 0.5, animated: false)
            return String(format: "Brightness: %.0f%%", (mediaService?.brightness ?? 0) * 100)
        case .verticalRight:
            mediaService?.setVolume((mediaService?.volume ?? 0.5) + delta * 0.5, animated: false)
            return String(format: "Volume: %.0f%%", (mediaService?.volume ?? 0) * 100)
        default:
            return nil
        }
    }

    public func handlePanEnd(direction: PlayerPanDirection) {
        if direction == .horizontal {
            processService?.endScrubbing()
            context?.add(self, event: .playerProgressEndScrubbing, option: .execOnlyOnce) { [weak self] _, _ in
                self?.isScrubbing = false
            }
        }
    }

    public func handleLongPressBegin() {
        previousSpeed = speedService?.currentSpeed ?? 1.0
        speedService?.setSpeed(2.0)
    }

    public func handleLongPressEnd() {
        speedService?.setSpeed(previousSpeed)
    }

    public func handlePinch(scale: CGFloat) -> String? {
        if scale > 1.2 {
            engineService?.scalingMode = .fill
        } else if scale < 0.8 {
            engineService?.scalingMode = .fit
        }
        let mode = engineService?.scalingMode == .fill ? "Fill" : "Fit"
        toastService?.showToast("Scale: \(mode)", style: .info, duration: 1.5)
        return mode
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
