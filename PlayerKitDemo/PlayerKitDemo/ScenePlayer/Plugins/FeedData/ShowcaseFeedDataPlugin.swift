import Foundation
import PlayerKit

@MainActor
public final class ShowcaseFeedDataPlugin: BasePlugin, ShowcaseFeedDataService {

    private var _video: ShowcaseVideo?
    private var _videoIndex: Int = -1

    public var video: ShowcaseVideo? { _video }
    public var videoIndex: Int { _videoIndex }

    @PlayerPlugin private var playerDataService: PlayerDataService?

    public required override init() {
        super.init()
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseFeedDataConfigModel else { return }
        applyModel(model)
    }

    public func clearData() {
        _video = nil
        _videoIndex = -1
    }

    private func syncToPlayerData() {
        guard let video = _video else { return }
        guard let playerDataService = playerDataService else { return }

        let config = PlayerDataConfigModel()
        var dataModel = PlayerDataModel()
        dataModel.vid = video.feedId
        dataModel.videoURL = video.url
        dataModel.title = video.title
        dataModel.author = video.creator.nickname
        dataModel.coverURL = video.coverURL
        dataModel.videoWidth = video.width
        dataModel.videoHeight = video.height
        dataModel.duration = video.duration
        config.initialDataModel = dataModel

        playerDataService.config(config)
    }

    private func applyModel(_ model: ShowcaseFeedDataConfigModel) {
        _video = model.video
        _videoIndex = model.index
        context?.post(.showcaseFeedDataDidUpdate, object: model.video, sender: self)
        syncToPlayerData()
    }
}
