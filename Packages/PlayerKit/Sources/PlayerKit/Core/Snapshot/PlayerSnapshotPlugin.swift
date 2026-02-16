import Foundation
import UIKit
import AVFoundation

@MainActor
public final class PlayerSnapshotPlugin: BasePlugin, PlayerSnapshotService {

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engine: PlayerEngineCoreService?

    public required override init() {
        super.init()
    }

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
