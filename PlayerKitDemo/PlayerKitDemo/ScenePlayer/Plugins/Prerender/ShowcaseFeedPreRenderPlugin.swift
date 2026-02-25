import UIKit
import PlayerKit

/// Feed 预渲染插件
/// 职责：管理预渲染配置的取消操作
/// 注意：不负责贴播放器视图，贴视图由 Cell 层统一处理
@MainActor
public final class ShowcaseFeedPreRenderPlugin: BasePlugin, ShowcaseFeedPreRenderService {

    @PlayerPlugin private var cellViewService: ShowcaseFeedCellViewService?
    @PlayerPlugin private var dataService: ShowcaseFeedDataService?

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }
}
