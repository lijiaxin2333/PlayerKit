import Foundation
import UIKit

/**
 * 快照服务协议，提供截取视频帧和生成缩略图能力
 */
@MainActor
public protocol PlayerSnapshotService: PluginService {

    /**
     * 同步获取当前帧图片
     */
    func currentFrameImage(size: CGSize?) -> UIImage?

    /**
     * 异步获取当前帧图片
     */
    func currentFrameImage(completion: @escaping (UIImage?) -> Void)

    /**
     * 在指定时间点生成缩略图
     */
    func generateThumbnail(at time: TimeInterval, size: CGSize?, completion: @escaping (UIImage?) -> Void)

    /**
     * 在多个时间点批量生成缩略图
     */
    func generateThumbnails(at times: [TimeInterval], size: CGSize?, completion: @escaping ([TimeInterval: UIImage]) -> Void)
}
