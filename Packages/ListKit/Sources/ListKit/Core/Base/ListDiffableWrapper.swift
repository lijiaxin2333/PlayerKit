import IGListKit

// MARK: - ListDiffableWrapper

final class ListDiffableWrapper: NSObject, IGListKit.ListDiffable {

    let wrapped: AnyObject

    init(_ object: AnyObject) {
        self.wrapped = object
    }

    func diffIdentifier() -> any NSObjectProtocol {
        return ObjectIdentifier(wrapped) as AnyObject as! NSObjectProtocol
    }

    func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        guard let other = object as? ListDiffableWrapper else { return false }
        return wrapped === other.wrapped
    }
}
