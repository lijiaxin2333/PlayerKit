import Foundation
import UIKit
import AVFoundation

/**
 * 快照插件，负责截取视频当前帧和生成缩略图
 */
@MainActor
public final class PlayerSnapshotPlugin: BasePlugin, PlayerSnapshotService {

    /** 引擎核心服务 */
    @PlayerPlugin private var engine: PlayerEngineCoreService?

    /**
     * 初始化
     */
    public required override init() {
        super.init()
    }

    /**
     * 同步获取当前帧图片（可指定最大尺寸）
     */
    public func currentFrameImage(size: CGSize?) -> UIImage? {
        guard let player = engine?.avPlayer,
              let item = player.currentItem,
              let track = item.asset.tracks(withMediaType: .video).first else { return nil }

        let currentTime = item.currentTime()
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        if let size = size {
            generator.maximumSize = size
        } else {
            let naturalSize = track.naturalSize
            generator.maximumSize = naturalSize
        }

        guard let cgImage = try? generator.copyCGImage(at: currentTime, actualTime: nil) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /**
     * 异步获取当前帧图片
     */
    public func currentFrameImage(completion: @escaping (UIImage?) -> Void) {
        guard let player = engine?.avPlayer,
              let item = player.currentItem else {
            completion(nil)
            return
        }

        let currentTime = item.currentTime()
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: currentTime)]) { _, cgImage, _, _, _ in
            DispatchQueue.main.async {
                if let cgImage = cgImage {
                    completion(UIImage(cgImage: cgImage))
                } else {
                    completion(nil)
                }
            }
        }
    }

    /**
     * 在指定时间点生成缩略图
     */
    public func generateThumbnail(at time: TimeInterval, size: CGSize?, completion: @escaping (UIImage?) -> Void) {
        guard let player = engine?.avPlayer,
              let item = player.currentItem else {
            completion(nil)
            return
        }

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        if let size = size {
            generator.maximumSize = size
        }

        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { _, cgImage, _, _, _ in
            DispatchQueue.main.async {
                if let cgImage = cgImage {
                    completion(UIImage(cgImage: cgImage))
                } else {
                    completion(nil)
                }
            }
        }
    }

    /**
     * 在多个时间点批量生成缩略图
     */
    public func generateThumbnails(at times: [TimeInterval], size: CGSize?, completion: @escaping ([TimeInterval: UIImage]) -> Void) {
        guard let player = engine?.avPlayer,
              let item = player.currentItem else {
            completion([:])
            return
        }

        let cmTimes = times.map { NSValue(time: CMTime(seconds: $0, preferredTimescale: 600)) }
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        if let size = size {
            generator.maximumSize = size
        }

        var result: [TimeInterval: UIImage] = [:]
        let total = cmTimes.count
        var count = 0

        generator.generateCGImagesAsynchronously(forTimes: cmTimes) { requestedTime, cgImage, _, _, _ in
            let seconds = CMTimeGetSeconds(requestedTime)
            if let cgImage = cgImage {
                result[seconds] = UIImage(cgImage: cgImage)
            }
            count += 1
            if count >= total {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }
}
