import Foundation
import PlayerKit

@MainActor
class ShowcaseFeedDataConfigModel {
    let video: ShowcaseVideo
    let index: Int

    init(video: ShowcaseVideo, index: Int) {
        self.video = video
        self.index = index
    }
}

@MainActor
protocol ShowcaseFeedDataService: CCLCompService {
    var video: ShowcaseVideo? { get }
    var videoIndex: Int { get }
    func clearData()
}

@MainActor
final class ShowcaseFeedDataComp: CCLBaseComp, ShowcaseFeedDataService {

    private var _video: ShowcaseVideo?
    private var _videoIndex: Int = -1

    var video: ShowcaseVideo? { _video }
    var videoIndex: Int { _videoIndex }

    required override init() {
        super.init()
    }

    override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
        context.add(self, event: .showcaseFeedDataWillUpdate) { [weak self] object, _ in
            guard let self = self, let model = object as? ShowcaseFeedDataConfigModel else { return }
            self._video = model.video
            self._videoIndex = model.index
            self.context?.post(.showcaseFeedDataDidUpdate, object: model.video, sender: self)
            self.syncToPlayerData()
        }
    }

    override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let model = configModel as? ShowcaseFeedDataConfigModel else { return }
        context?.post(.showcaseFeedDataWillUpdate, object: model, sender: self)
        _video = model.video
        _videoIndex = model.index
        context?.post(.showcaseFeedDataDidUpdate, object: model.video, sender: self)
        syncToPlayerData()
    }

    func clearData() {
        _video = nil
        _videoIndex = -1
    }

    private func syncToPlayerData() {
        guard let video = _video else { return }
        guard let playerDataService = context?.resolveService(PlayerDataService.self) else { return }

        let config = PlayerDataConfigModel()
        var dataModel = PlayerDataModel()
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
}
