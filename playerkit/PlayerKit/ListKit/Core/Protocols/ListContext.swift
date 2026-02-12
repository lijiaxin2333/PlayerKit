import UIKit

@MainActor
public protocol ListContext: ListBaseInfo, ListUIInfo, ListOperation, ListNotification {
}
