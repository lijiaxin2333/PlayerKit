import UIKit
import PlayerKit

@MainActor
public protocol ShowcaseFeedPreRenderService: PluginService {
    func attachPrerenderPlayerView()
    func removePrerenderPlayerView()
}

@MainActor
public final class ShowcaseFeedPreRenderConfigModel {
    public let cancelPreRender: (String) -> Void

    public init(cancelPreRender: @escaping (String) -> Void) {
        self.cancelPreRender = cancelPreRender
    }
}
