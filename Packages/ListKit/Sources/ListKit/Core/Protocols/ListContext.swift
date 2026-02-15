import UIKit

/// 列表上下文协议（组合协议）
/// 组合了列表的基础信息、UI信息、操作能力和消息通知能力
/// - 实现者: BaseListViewController
/// - 使用者: SectionController、Cell、Plugin
/// - 职责: 提供列表的完整上下文能力，是组件与列表交互的主要接口
@MainActor
public protocol ListContext: ListBaseInfo, ListUIInfo, ListOperation, ListNotification {
}
