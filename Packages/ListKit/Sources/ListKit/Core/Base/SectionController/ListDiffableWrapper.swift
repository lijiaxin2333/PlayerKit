import IGListKit

/// Diffable 包装器
/// 将任意 AnyObject 包装为 IGListDiffable，用于 Diff 计算
final class ListDiffableWrapper: NSObject, IGListKit.ListDiffable {

    /// 被包装的对象
    let wrapped: AnyObject

    init(_ object: AnyObject) {
        self.wrapped = object
    }

    /// Diff 标识符（使用对象地址）
    func diffIdentifier() -> any NSObjectProtocol {
        return ObjectIdentifier(wrapped) as AnyObject as! NSObjectProtocol
    }

    /// 判断是否与 Diff 对象相等（使用指针比较）
    func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        guard let other = object as? ListDiffableWrapper else { return false }
        return wrapped === other.wrapped
    }
}
