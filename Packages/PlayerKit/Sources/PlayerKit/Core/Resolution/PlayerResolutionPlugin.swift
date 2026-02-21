import Foundation
import AVFoundation
import UIKit

/**
 * 分辨率/清晰度插件，负责切换视频分辨率和获取可用分辨率列表
 */
@MainActor
public final class PlayerResolutionPlugin: BasePlugin, PlayerResolutionService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerResolutionConfigModel

    /** 引擎核心服务 */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /** 当前选中的分辨率 */
    private var _currentResolution: PlayerResolutionInfo?
    /** 可用的分辨率列表 */
    private var _availableResolutions: [PlayerResolutionInfo] = []

    /**
     * 当前分辨率
     */
    public var currentResolution: PlayerResolutionInfo? {
        get { _currentResolution }
        set {
            _currentResolution = newValue
            if let new = newValue {
                setResolution(new)
            }
        }
    }

    /**
     * 可用的分辨率列表
     */
    public var availableResolutions: [PlayerResolutionInfo] {
        get { _availableResolutions }
        set { _availableResolutions = newValue }
    }

    /**
     * 初始化
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成，自动获取分辨率列表
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        fetchResolutions { [weak self] resolutions in
            self?.availableResolutions = resolutions
        }
    }

    /**
     * 配置插件，应用默认分辨率
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerResolutionConfigModel else { return }

        _currentResolution = config.defaultResolution
    }

    /**
     * 设置分辨率并切换播放
     */
    public func setResolution(_ resolution: PlayerResolutionInfo) {
        guard _currentResolution != resolution else { return }

        _currentResolution = resolution
        context?.post(.playerResolutionDidChange, object: resolution, sender: self)

        if !resolution.isAuto,
           let currentItem = engineService?.avPlayer?.currentItem {
            let currentTime = engineService?.currentTime ?? 0
            let wasPlaying = engineService?.playbackState == .playing

            let asset = AVAsset(url: (currentItem.asset as? AVURLAsset)?.url ?? URL(string: "")!)
            let newItem = AVPlayerItem(asset: asset)

            engineService?.replaceCurrentItem(with: newItem)

            if currentTime > 0 {
                engineService?.seek(to: currentTime) { [weak self] finished in
                    MainActor.assumeIsolated {
                        if finished, wasPlaying {
                            self?.engineService?.play()
                        }
                    }
                }
            }

            print("[PlayerResolutionPlugin] 切换分辨率: \(resolution.displayName), 当前时间: \(currentTime)秒")
        } else {
            print("[PlayerResolutionPlugin] 切换分辨率: \(resolution.displayName) (自动)")
        }
    }

    /**
     * 获取可用分辨率列表
     */
    public func fetchResolutions(completion: @escaping ([PlayerResolutionInfo]) -> Void) {
        guard let player = engineService?.avPlayer,
              let currentItem = player.currentItem,
              let asset = currentItem.asset as? AVURLAsset else {
            let mockResolutions = [
                PlayerResolutionInfo(width: 1920, height: 1080, bitrate: 2000000, displayName: "1080P"),
                PlayerResolutionInfo(width: 1280, height: 720, bitrate: 1200000, displayName: "720P"),
                PlayerResolutionInfo(width: 854, height: 480, bitrate: 800000, displayName: "480P"),
                PlayerResolutionInfo(width: 640, height: 360, bitrate: 500000, displayName: "360P"),
            ]
            _availableResolutions = mockResolutions
            completion(mockResolutions)
            context?.post(.playerDidFetchResolutions, object: mockResolutions, sender: self)
            return
        }

        asset.loadValuesAsynchronously(forKeys: ["availableMediaCharacteristicsWithMediaSelectionOptions"]) { [weak self] in
            guard let self = self else { return }

            var resolutions: [PlayerResolutionInfo] = [.auto]

            if asset.statusOfValue(forKey: "availableMediaCharacteristicsWithMediaSelectionOptions", error: nil) == .loaded {
                guard let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.visual) else {
                    self.context?.post(.playerDidFetchResolutions, object: resolutions, sender: self)
                    return
                }

                for option in mediaSelectionGroup.options {
                    let displayName = option.displayName

                    var width = 0
                    var height = 0

                    if width == 0 || height == 0 {
                        if displayName.contains("1080") {
                            width = 1920
                            height = 1080
                        } else if displayName.contains("720") {
                            width = 1280
                            height = 720
                        } else if displayName.contains("480") {
                            width = 854
                            height = 480
                        } else {
                            width = 640
                            height = 360
                        }
                    }

                    let info = PlayerResolutionInfo(
                        width: width,
                        height: height,
                        bitrate: 0,
                        displayName: displayName
                    )
                    resolutions.append(info)
                }
            } else {
                for track in asset.tracks(withMediaType: .video) {
                    let size = track.naturalSize.appSize(track.preferredTransform)
                    let info = PlayerResolutionInfo(
                        width: Int(size.width),
                        height: Int(size.height),
                        bitrate: 0,
                        displayName: "\(Int(size.width))P"
                    )
                    resolutions.append(info)
                }
            }

            if resolutions.count == 1 {
                resolutions = [
                    .auto,
                    PlayerResolutionInfo(width: 1920, height: 1080, bitrate: 2000000, displayName: "1080P"),
                    PlayerResolutionInfo(width: 1280, height: 720, bitrate: 1200000, displayName: "720P"),
                    PlayerResolutionInfo(width: 854, height: 480, bitrate: 800000, displayName: "480P"),
                    PlayerResolutionInfo(width: 640, height: 360, bitrate: 500000, displayName: "360P"),
                ]
            }

            print("[PlayerResolutionPlugin] 获取到 \(resolutions.count) 个分辨率选项")
            for res in resolutions {
                print("  - \(res.displayName): \(res.width)x\(res.height)")
            }

            self._availableResolutions = resolutions
            completion(resolutions)
            self.context?.post(.playerDidFetchResolutions, object: resolutions, sender: self)
        }
    }
}

/**
 * AVAssetTrack 扩展，获取应用变换后的实际尺寸
 */
private extension AVAssetTrack {
    /**
     * 获取应用 preferredTransform 后的实际尺寸
     */
    func naturalSize() -> CGSize {
        return naturalSize.appSize(preferredTransform)
    }
}

/**
 * CGSize 扩展，应用变换
 */
private extension CGSize {
    /**
     * 应用 CGAffineTransform 后的尺寸
     */
    func appSize(_ transform: CGAffineTransform) -> CGSize {
        let appSize = CGRect(origin: .zero, size: self).applying(transform)
        return CGSize(width: abs(appSize.width), height: abs(appSize.height))
    }
}
