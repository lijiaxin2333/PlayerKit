import UIKit
import PlayerKit

@MainActor
class ShowcaseDetailControlConfigModel {
    let video: ShowcaseVideo
    let allVideos: [ShowcaseVideo]
    let videoIndex: Int
    weak var gestureView: UIView?

    init(video: ShowcaseVideo, allVideos: [ShowcaseVideo], videoIndex: Int, gestureView: UIView) {
        self.video = video
        self.allVideos = allVideos
        self.videoIndex = videoIndex
        self.gestureView = gestureView
    }
}

@MainActor
protocol ShowcaseDetailControlService: PluginService {
    var isScrubbing: Bool { get }
    var onPlaybackStateChanged: ((Bool) -> Void)? { get set }
    var onProgressUpdate: ((Float, String, String) -> Void)? { get set }
    var onControlShouldShow: ((Bool) -> Void)? { get set }
    func teardown()
    func togglePlayPause()
    func cycleSpeed() -> Float
    func toggleMute() -> Bool
    func toggleLoop() -> Bool
    func toggleSubtitle() -> Bool
    func captureSnapshot(completion: @escaping (UIImage?) -> Void)
    func toggleFullScreen()
    func showDebugPanel()
    func beginSliderScrub()
    func sliderChanged(to value: Float) -> String?
    func endSliderScrub()
    func scheduleControlHide()
    func qosMetrics() -> PlayerQosMetrics?
    func preNextInfo() -> (title: String?, isLoading: Bool)
    func contextName() -> String
    func handlePanBegin(direction: PlayerPanDirection)
    func handlePanChange(direction: PlayerPanDirection, delta: Float) -> String?
    func handlePanEnd(direction: PlayerPanDirection)
    func handleLongPressBegin()
    func handleLongPressEnd()
    func handlePinch(scale: CGFloat) -> String?
}

@MainActor
final class ShowcaseDetailControlPlugin: BasePlugin, ShowcaseDetailControlService {

    private var video: ShowcaseVideo?
    private var videoIndex: Int = 0

    private(set) var isScrubbing = false
    private var previousSpeed: Float = 1.0
    private var controlHideTimer: Timer?

    var onPlaybackStateChanged: ((Bool) -> Void)?
    var onProgressUpdate: ((Float, String, String) -> Void)?
    var onControlShouldShow: ((Bool) -> Void)?

    private var engineService: PlayerEngineCoreService? {
        context?.resolveService(PlayerEngineCoreService.self)
    }

    private var processService: PlayerProcessService? {
        context?.resolveService(PlayerProcessService.self)
    }

    private var speedService: PlayerSpeedService? {
        context?.resolveService(PlayerSpeedService.self)
    }

    override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseDetailControlConfigModel else { return }
        guard let gestureView = model.gestureView else { return }
        self.video = model.video
        self.videoIndex = model.videoIndex

        setupGestures(gestureView: gestureView)
        setupStartTime(video: model.video)
        setupQos()
        setupTracker(video: model.video)
        setupPreNext(allVideos: model.allVideos, videoIndex: model.videoIndex)
        observeEvents()
    }

    func teardown() {
        controlHideTimer?.invalidate()
        controlHideTimer = nil

        context?.resolveService(PlayerStartTimeService.self)?.cacheCurrentProgress()
        context?.resolveService(PlayerTrackerService.self)?.sendEvent("detail_exit", params: ["video_id": video?.feedId ?? ""])

        let qos = context?.resolveService(PlayerQosService.self)
        qos?.stopQosMonitoring()

        let gestureService = context?.resolveService(PlayerGestureService.self)
        gestureService?.isPanEnabled = false
        gestureService?.isPinchEnabled = false
        gestureService?.gestureView = nil

        processService?.removeProgressObserver(self)
        context?.removeHandlers(forObserver: self)

        onPlaybackStateChanged = nil
        onProgressUpdate = nil
        onControlShouldShow = nil
    }

    private func setupGestures(gestureView: UIView) {
        guard let gestureService = context?.resolveService(PlayerGestureService.self) else { return }
        gestureService.gestureView = gestureView
        gestureService.isPanEnabled = true
        gestureService.isPinchEnabled = true
    }

    private func setupStartTime(video: ShowcaseVideo) {
        guard let startTimeService = context?.resolveService(PlayerStartTimeService.self) else { return }
        startTimeService.cacheProgressEnabled = true
        if let url = video.url {
            let key = url.absoluteString
            if let cached = startTimeService.cachedProgress(forKey: key) {
                startTimeService.setStartTime(cached)
            }
        }
    }

    private func setupQos() {
        let qos = context?.resolveService(PlayerQosService.self)
        qos?.startQosMonitoring()
    }

    private func setupTracker(video: ShowcaseVideo) {
        context?.resolveService(PlayerTrackerService.self)?.sendEvent("detail_enter", params: [
            "video_id": video.feedId,
            "video_index": videoIndex
        ])
    }

    private func setupPreNext(allVideos: [ShowcaseVideo], videoIndex: Int) {
        let nextIndex = videoIndex + 1
        guard nextIndex < allVideos.count, let url = allVideos[nextIndex].url else { return }
        let preNext = context?.resolveService(PlayerPreNextService.self)
        preNext?.setNextItem(PlayerPreNextItem(url: url, title: allVideos[nextIndex].title))
        preNext?.startPreload()
    }

    private func observeEvents() {
        guard let ctx = context else { return }

        processService?.observeProgress { [weak self] progress, time in
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
            let tip = self?.context?.resolveService(PlayerTipManagerService.self)
            tip?.showTip(.buffering, message: "Buffering...")
        }

        ctx.add(self, event: .playerPlayingStalledEnd) { [weak self] _, _ in
            let tip = self?.context?.resolveService(PlayerTipManagerService.self)
            tip?.hideTip(.buffering)
        }

        ctx.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            guard let self = self else { return }
            let finish = self.context?.resolveService(PlayerFinishViewService.self)
            finish?.showFinishView()
            self.onControlShouldShow?(true)

            self.context?.resolveService(PlayerStartTimeService.self)?.cacheCurrentProgress()
            self.context?.resolveService(PlayerTrackerService.self)?.sendEvent("playback_finish", params: ["video_id": self.video?.feedId ?? ""])
        }
    }

    func togglePlayPause() {
        let playback = context?.resolveService(PlayerPlaybackControlService.self)
        playback?.togglePlayPause()
        scheduleControlHide()
    }

    func cycleSpeed() -> Float {
        guard let speedService = speedService else { return 1.0 }
        let speeds: [Float] = [0.5, 1.0, 1.5, 2.0]
        let current = speedService.currentSpeed
        let nextIdx = (speeds.firstIndex(of: current) ?? 1) + 1
        let next = speeds[nextIdx % speeds.count]
        speedService.setSpeed(next)

        let toast = context?.resolveService(PlayerToastService.self)
        toast?.showToast("Speed: \(next)x", style: .info, duration: 1.5)
        return next
    }

    func toggleMute() -> Bool {
        let media = context?.resolveService(PlayerMediaControlService.self)
        media?.toggleMute()
        return media?.isMuted == true
    }

    func toggleLoop() -> Bool {
        guard let engine = engineService else { return false }
        engine.isLooping.toggle()
        let toast = context?.resolveService(PlayerToastService.self)
        toast?.showToast(engine.isLooping ? "Loop: ON" : "Loop: OFF", style: .info, duration: 1.5)
        return engine.isLooping
    }

    func toggleSubtitle() -> Bool {
        guard let subtitleService = context?.resolveService(PlayerSubtitleService.self) else { return false }
        subtitleService.isEnabled.toggle()
        let toast = context?.resolveService(PlayerToastService.self)
        toast?.showToast(subtitleService.isEnabled ? "Subtitles: ON" : "Subtitles: OFF", style: .info, duration: 1.5)
        return subtitleService.isEnabled
    }

    func captureSnapshot(completion: @escaping (UIImage?) -> Void) {
        context?.resolveService(PlayerSnapshotService.self)?.currentFrameImage { [weak self] image in
            guard let self = self else { completion(nil); return }
            if image != nil {
                let toast = self.context?.resolveService(PlayerToastService.self)
                toast?.showToast("Screenshot captured!", style: .success, duration: 2.0)
                self.context?.resolveService(PlayerTrackerService.self)?.sendEvent("snapshot", params: ["video_id": self.video?.feedId ?? ""])
            }
            completion(image)
        }
    }

    func toggleFullScreen() {
        let fs = context?.resolveService(PlayerFullScreenService.self)
        fs?.toggleFullScreen(orientation: .auto, animated: true)
    }

    func showDebugPanel() {
        let debug = context?.resolveService(PlayerDebugService.self)
        debug?.isDebugEnabled = true
        debug?.showDebugPanel()
    }

    func beginSliderScrub() {
        isScrubbing = true
        processService?.beginScrubbing()
    }

    func sliderChanged(to value: Float) -> String? {
        processService?.scrubbing(to: Double(value))
        if let duration = engineService?.duration {
            return formatTime(TimeInterval(value) * duration)
        }
        return nil
    }

    func endSliderScrub() {
        processService?.endScrubbing()
        context?.add(self, event: .playerProgressEndScrubbing, option: .execOnlyOnce) { [weak self] _, _ in
            self?.isScrubbing = false
        }
    }

    func scheduleControlHide() {
        controlHideTimer?.invalidate()
        controlHideTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.engineService?.playbackState == .playing {
                self.onControlShouldShow?(false)
            }
        }
    }

    func qosMetrics() -> PlayerQosMetrics? {
        let qos = context?.resolveService(PlayerQosService.self)
        return qos?.qosMetrics
    }

    func preNextInfo() -> (title: String?, isLoading: Bool) {
        let preNext = context?.resolveService(PlayerPreNextService.self)
        return (preNext?.nextItem?.title, preNext?.isPreloading == true)
    }

    func contextName() -> String {
        (context as? Context)?.name ?? "N/A"
    }

    func handlePanBegin(direction: PlayerPanDirection) {
        if direction == .horizontal {
            isScrubbing = true
            processService?.beginScrubbing()
        }
    }

    func handlePanChange(direction: PlayerPanDirection, delta: Float) -> String? {
        let media = context?.resolveService(PlayerMediaControlService.self)

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
            media?.setBrightness((media?.brightness ?? 0.5) + delta * 0.5, animated: false)
            return String(format: "Brightness: %.0f%%", (media?.brightness ?? 0) * 100)
        case .verticalRight:
            media?.setVolume((media?.volume ?? 0.5) + delta * 0.5, animated: false)
            return String(format: "Volume: %.0f%%", (media?.volume ?? 0) * 100)
        default:
            return nil
        }
    }

    func handlePanEnd(direction: PlayerPanDirection) {
        if direction == .horizontal {
            processService?.endScrubbing()
            context?.add(self, event: .playerProgressEndScrubbing, option: .execOnlyOnce) { [weak self] _, _ in
                self?.isScrubbing = false
            }
        }
    }

    func handleLongPressBegin() {
        previousSpeed = speedService?.currentSpeed ?? 1.0
        speedService?.setSpeed(2.0)
    }

    func handleLongPressEnd() {
        speedService?.setSpeed(previousSpeed)
    }

    func handlePinch(scale: CGFloat) -> String? {
        let engine = engineService
        if scale > 1.2 {
            engine?.scalingMode = .fill
        } else if scale < 0.8 {
            engine?.scalingMode = .fit
        }
        let toast = context?.resolveService(PlayerToastService.self)
        let mode = engine?.scalingMode == .fill ? "Fill" : "Fit"
        toast?.showToast("Scale: \(mode)", style: .info, duration: 1.5)
        return mode
    }

    private func formatTime(_ time: TimeInterval) -> String {
        guard time.isFinite, time >= 0 else { return "00:00" }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
