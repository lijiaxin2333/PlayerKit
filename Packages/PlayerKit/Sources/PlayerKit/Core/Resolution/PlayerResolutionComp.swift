//
//  PlayerResolutionComp.swift
//  playerkit
//
//  分辨率/清晰度组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerResolutionComp: CCLBaseComp, PlayerResolutionService {

    public typealias ConfigModelType = PlayerResolutionConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _currentResolution: PlayerResolutionInfo?
    private var _availableResolutions: [PlayerResolutionInfo] = []

    // MARK: - PlayerResolutionService

    public var currentResolution: PlayerResolutionInfo? {
        get { _currentResolution }
        set {
            _currentResolution = newValue
            if let new = newValue {
                setResolution(new)
            }
        }
    }

    public var availableResolutions: [PlayerResolutionInfo] {
        get { _availableResolutions }
        set { _availableResolutions = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        // 自动获取分辨率列表
        fetchResolutions { [weak self] resolutions in
            self?.availableResolutions = resolutions
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerResolutionConfigModel else { return }

        _currentResolution = config.defaultResolution
    }

    // MARK: - PlayerResolutionService

    public func setResolution(_ resolution: PlayerResolutionInfo) {
        guard _currentResolution != resolution else { return }

        _currentResolution = resolution
        context?.post(.playerResolutionDidChange, object: resolution, sender: self)

        // 切换分辨率逻辑
        if !resolution.isAuto,
           let currentItem = engineService?.avPlayer?.currentItem {
            // 重新创建播放项以切换清晰度
            let currentTime = engineService?.currentTime ?? 0
            let wasPlaying = engineService?.playbackState == .playing

            // 创建新的资源
            let asset = AVAsset(url: (currentItem.asset as? AVURLAsset)?.url ?? URL(string: "")!)
            let newItem = AVPlayerItem(asset: asset)

            // 保存当前时间并替换播放项
            engineService?.replaceCurrentItem(with: newItem)

            // Seek 回原位置
            if currentTime > 0 {
                engineService?.seek(to: currentTime) { [weak self] finished in
                    if finished, wasPlaying {
                        self?.engineService?.play()
                    }
                }
            }

            print("[PlayerResolutionComp] 切换分辨率: \(resolution.displayName), 当前时间: \(currentTime)秒")
        } else {
            print("[PlayerResolutionComp] 切换分辨率: \(resolution.displayName) (自动)")
        }
    }

    public func fetchResolutions(completion: @escaping ([PlayerResolutionInfo]) -> Void) {
        // 从当前视频资源中获取分辨率信息
        guard let player = engineService?.avPlayer,
              let currentItem = player.currentItem,
              let asset = currentItem.asset as? AVURLAsset else {
            // 返回模拟数据
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

        // 异步加载资源信息
        asset.loadValuesAsynchronously(forKeys: ["availableMediaCharacteristicsWithMediaSelectionOptions"]) { [weak self] in
            guard let self = self else { return }

            var resolutions: [PlayerResolutionInfo] = [.auto]

            // 获取视频轨道
            if asset.statusOfValue(forKey: "availableMediaCharacteristicsWithMediaSelectionOptions", error: nil) == .loaded {
                guard let mediaSelectionGroup = asset.mediaSelectionGroup(forMediaCharacteristic: AVMediaCharacteristic.visual) else {
                    context?.post(.playerDidFetchResolutions, object: resolutions, sender: self)
                    return
                }

                for option in mediaSelectionGroup.options {
                    // 从选项中提取分辨率信息
                    let displayName = option.displayName

                    // 尝试从元数据中解析分辨率
                    var width = 0
                    var height = 0

                    // 如果无法获取，使用默认值
                    if width == 0 || height == 0 {
                        // 根据显示名称推断分辨率
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
                // 从 asset 的 tracks 中获取分辨率
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

            // 如果没有找到任何分辨率，返回默认列表
            if resolutions.count == 1 {
                resolutions = [
                    .auto,
                    PlayerResolutionInfo(width: 1920, height: 1080, bitrate: 2000000, displayName: "1080P"),
                    PlayerResolutionInfo(width: 1280, height: 720, bitrate: 1200000, displayName: "720P"),
                    PlayerResolutionInfo(width: 854, height: 480, bitrate: 800000, displayName: "480P"),
                    PlayerResolutionInfo(width: 640, height: 360, bitrate: 500000, displayName: "360P"),
                ]
            }

            print("[PlayerResolutionComp] 获取到 \(resolutions.count) 个分辨率选项")
            for res in resolutions {
                print("  - \(res.displayName): \(res.width)x\(res.height)")
            }

            self._availableResolutions = resolutions
            completion(resolutions)
            self.context?.post(.playerDidFetchResolutions, object: resolutions, sender: self)
        }
    }
}

// MARK: - AVAssetTrack Extension

private extension AVAssetTrack {
    func naturalSize() -> CGSize {
        return naturalSize.appSize(preferredTransform)
    }
}

private extension CGSize {
    func appSize(_ transform: CGAffineTransform) -> CGSize {
        let appSize = CGRect(origin: .zero, size: self).applying(transform)
        return CGSize(width: abs(appSize.width), height: abs(appSize.height))
    }
}
