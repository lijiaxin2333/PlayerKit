import UIKit
import PlayerKit

/// Feed 预渲染服务协议
/// 职责：管理预渲染配置的取消操作
@MainActor
public protocol ShowcaseFeedPreRenderService: PluginService {
}

/// 预渲染配置模型
@MainActor
public final class ShowcaseFeedPreRenderConfigModel {
    public let cancelPreRender: (String) -> Void

    public init(cancelPreRender: @escaping (String) -> Void) {
        self.cancelPreRender = cancelPreRender
    }
}
