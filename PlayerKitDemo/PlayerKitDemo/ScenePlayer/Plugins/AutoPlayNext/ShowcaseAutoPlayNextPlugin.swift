import Foundation
import PlayerKit

@MainActor
public final class ShowcaseAutoPlayNextPlugin: BasePlugin, ShowcaseAutoPlayNextService {

    @PlayerPlugin private var dataService: ShowcaseFeedDataService?
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _isEnabled: Bool = true
    private var _totalCount: Int = 0

    public var isEnabled: Bool {
        get { _isEnabled }
        set { _isEnabled = newValue }
    }

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        context.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            self?.handlePlaybackFinished()
        }
    }

    public override func config(_ configModel: Any?) {
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
