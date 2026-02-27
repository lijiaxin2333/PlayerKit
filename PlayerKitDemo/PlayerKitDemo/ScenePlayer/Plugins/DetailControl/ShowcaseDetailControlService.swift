import UIKit
import BizPlayerKit

@MainActor
public class ShowcaseDetailControlConfigModel {
    public let video: ShowcaseVideo
    public let allVideos: [ShowcaseVideo]
    public let videoIndex: Int
    public weak var gestureView: UIView?

    public init(video: ShowcaseVideo, allVideos: [ShowcaseVideo], videoIndex: Int, gestureView: UIView) {
        self.video = video
        self.allVideos = allVideos
        self.videoIndex = videoIndex
        self.gestureView = gestureView
    }
}

@MainActor
public protocol ShowcaseDetailControlService: PluginService {
    var isScrubbing: Bool { get }
    var onPlaybackStateChanged: ((Bool) -> Void)? { get set }
    var onProgressUpdate: ((Float, String, String) -> Void)? { get set }
    var onControlShouldShow: ((Bool) -> Void)? { get set }
    func teardown()
    func togglePlayPause()
    func cycleSpeed() -> Float
    func toggleMute() -> Bool
    func toggleLoop() -> Bool
    func captureSnapshot(completion: @escaping (UIImage?) -> Void)
    func toggleFullScreen()
    func showDebugPanel()
    func beginSliderScrub()
    func sliderChanged(to value: Float) -> String?
    func endSliderScrub()
    func scheduleControlHide()
    func contextName() -> String
    func handlePanBegin(direction: PlayerPanDirection)
    func handlePanChange(direction: PlayerPanDirection, delta: Float) -> String?
    func handlePanEnd(direction: PlayerPanDirection)
    func handleLongPressBegin()
    func handleLongPressEnd()
    func handlePinch(scale: CGFloat) -> String?
}
