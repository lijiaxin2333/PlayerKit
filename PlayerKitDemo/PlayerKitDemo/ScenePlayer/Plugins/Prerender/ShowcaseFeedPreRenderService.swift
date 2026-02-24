import UIKit
import PlayerKit

@MainActor
public protocol ShowcaseFeedPreRenderService: PluginService {
    func attachPrerenderPlayerView()
    func removePrerenderPlayerView()
}

@MainActor
public final class ShowcaseFeedPreRenderConfigModel {
    public let consumePreRendered: (String) -> Player?
    public let cancelPreRender: (String) -> Void

    public init(consumePreRendered: @escaping (String) -> Player?,
         cancelPreRender: @escaping (String) -> Void) {
        self.consumePreRendered = consumePreRendered
        self.cancelPreRender = cancelPreRender
    }
}
