import UIKit
import BizPlayerKit

@MainActor
public protocol ShowcaseFeedOverlayService: PluginService {
    var gradientView: ShowcaseFeedGradientView { get }
    var infoView: ShowcaseFeedInfoView { get }
    var socialView: ShowcaseFeedSocialView { get }
    func bringOverlaysToFront()
}
