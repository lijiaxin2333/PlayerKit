import Foundation
import BizPlayerKit

@MainActor
public class ShowcaseFeedDataConfigModel {
    public let video: ShowcaseVideo
    public let index: Int

    public init(video: ShowcaseVideo, index: Int) {
        self.video = video
        self.index = index
    }
}

@MainActor
public protocol ShowcaseFeedDataService: PluginService {
    var video: ShowcaseVideo? { get }
    var videoIndex: Int { get }
    func clearData()
}
