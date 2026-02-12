import Foundation
import UIKit

@MainActor
public protocol PlayerSnapshotService: CCLCompService {

    func currentFrameImage(size: CGSize?) -> UIImage?

    func currentFrameImage(completion: @escaping (UIImage?) -> Void)

    func generateThumbnail(at time: TimeInterval, size: CGSize?, completion: @escaping (UIImage?) -> Void)

    func generateThumbnails(at times: [TimeInterval], size: CGSize?, completion: @escaping ([TimeInterval: UIImage]) -> Void)
}
