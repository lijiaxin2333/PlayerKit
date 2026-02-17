import Foundation
import PlayerKit

@MainActor
protocol ShowcaseAutoPlayNextService: PluginService {
    var isEnabled: Bool { get set }
}

@MainActor
final class ShowcaseAutoPlayNextConfigModel {
    var totalCount: Int = 0
    var isEnabled: Bool = true

    init(totalCount: Int, isEnabled: Bool = true) {
        self.totalCount = totalCount
        self.isEnabled = isEnabled
    }
}

@MainActor
final class ShowcaseAutoPlayNextPlugin: BasePlugin, ShowcaseAutoPlayNextService {

    @PlayerPlugin private var dataService: ShowcaseFeedDataService?
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _isEnabled: Bool = true
    private var _totalCount: Int = 0

    var isEnabled: Bool {
        get { _isEnabled }
        set { _isEnabled = newValue }
    }

    required override init() {
        super.init()
    }

    override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        context.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            self?.handlePlaybackFinished()
        }
    }

    override func config(_ configModel: Any?) {
        super.config(configModel)
        guard let config = configModel as? ShowcaseAutoPlayNextConfigModel else { return }
        _totalCount = config.totalCount
        _isEnabled = config.isEnabled
    }

    private func handlePlaybackFinished() {
        guard _isEnabled else { return }
        let currentIndex = dataService?.videoIndex ?? -1
        guard currentIndex >= 0 else { return }

        if currentIndex + 1 < _totalCount {
            context?.post(.showcaseAutoPlayNextRequest, object: currentIndex, sender: self)
        } else {
            engineService?.seek(to: 0)
            engineService?.play()
        }
    }
}
