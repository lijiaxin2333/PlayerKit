import Foundation
import BizPlayerKit

@MainActor
public protocol ShowcaseAutoPlayNextService: PluginService {
    var isEnabled: Bool { get set }
}

@MainActor
public final class ShowcaseAutoPlayNextConfigModel {
    public var totalCount: Int = 0
    public var isEnabled: Bool = true

    public init(totalCount: Int, isEnabled: Bool = true) {
        self.totalCount = totalCount
        self.isEnabled = isEnabled
    }
}
