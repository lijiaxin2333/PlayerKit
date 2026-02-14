import UIKit
import IGListKit

@MainActor
open class BaseListSectionViewModel: NSObject, IGListKit.ListDiffable, ListSectionViewModelProtocol {

    public private(set) var modelsArray: [AnyObject]

    public var inset: UIEdgeInsets = .zero
    public var columnCount: Int = 0
    public var minimumLineSpacing: CGFloat = 0
    public var minimumInteritemSpacing: CGFloat = 0

    public var dataSourceState: ListDataSourceState = .none
    public var dataSourceHasMore: Bool = false
    public var refreshState: ListDataLoadState = .isNotLoading
    public var loadMoreState: ListDataLoadState = .isNotLoading
    public var errorMessage: String = ""

    public private(set) weak var listContext: ListContext?
    public private(set) var responseModel: Any?
    public private(set) var isVisible: Bool = false

    public weak var sectionContext: ListSectionContext?
    public weak var containerConfig: ListContainerConfig?

    public init(modelsArray: [AnyObject] = []) {
        self.modelsArray = Self.removeDuplicates(modelsArray)
        super.init()
    }

    public init(listContext: ListContext?, responseModel: Any?) {
        self.listContext = listContext
        self.responseModel = responseModel
        self.modelsArray = []
        super.init()
    }

    public func updateListContext(_ context: ListContext?) {
        self.listContext = context
    }

    public func updateVisibility(_ visible: Bool) {
        self.isVisible = visible
    }

    open class func sectionControllerClass() -> BaseListSectionController.Type? {
        let vmClassName = NSStringFromClass(self)
        let scClassName = vmClassName.replacingOccurrences(of: "SectionViewModel", with: "SectionController")
        return NSClassFromString(scClassName) as? BaseListSectionController.Type
    }

    // MARK: - Model Operations

    public func appendModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !models.isEmpty else { return }
        let cleaned = Self.removeDuplicates(models)
        if modelsArray.isEmpty {
            modelsArray = cleaned
            sectionContext?.reloadSection(animated: animated, completion: completion)
            return
        }
        modelsArray.append(contentsOf: cleaned)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    public func removeModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard !models.isEmpty else { return }
        modelsArray.removeAll { item in models.contains(where: { $0 === item }) }
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    public func removeAllModels(animated: Bool = false) {
        modelsArray = []
        sectionContext?.reloadSection(animated: animated, completion: nil)
    }

    public func reloadByModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        modelsArray = Self.removeDuplicates(models)
        sectionContext?.reloadSection(animated: animated, completion: completion)
    }

    public func updateByModels(_ models: [AnyObject], animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        modelsArray = Self.removeDuplicates(models)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    public func insertModel(_ model: AnyObject, atIndex index: Int, animated: Bool = false, completion: ((Bool) -> Void)? = nil) {
        guard index <= modelsArray.count else { return }
        guard !modelsArray.contains(where: { $0 === model }) else { return }
        if index == modelsArray.count {
            appendModels([model], animated: animated, completion: completion)
            return
        }
        modelsArray.insert(model, at: index)
        sectionContext?.updateSection(animated: animated, completion: completion)
    }

    public func moveItem(fromIndex source: Int, toIndex dest: Int) {
        guard source < modelsArray.count, dest < modelsArray.count else { return }
        let item = modelsArray.remove(at: source)
        modelsArray.insert(item, at: dest)
    }

    public func scrollToItem(atIndex index: Int, scrollPosition: UICollectionView.ScrollPosition, animated: Bool) {
        sectionContext?.scrollToItem(atIndex: index, scrollPosition: scrollPosition, animated: animated)
    }

    open func fetchSectionData() {}
    open func loadMoreSectionData() {}

    // MARK: - Section Operations

    public func reloadVisibleSection() {
        sectionContext?.reloadSection(animated: false, completion: nil)
    }

    public func reloadCurrentSection() {
        sectionContext?.reloadSection(animated: false, completion: nil)
    }

    public func reloadCurrentSection(animated: Bool, completion: ((Bool) -> Void)?) {
        sectionContext?.reloadSection(animated: animated, completion: completion)
    }

    public func updateCurrentSection() {
        sectionContext?.updateSection(animated: false, completion: nil)
    }

    public func removeCurrentSectionWithCompletion(_ completion: ((Bool) -> Void)?, animated: Bool) {
        guard let listVM = listContext?.listViewModel() else { return }
        listVM.removeSectionViewModels([self], animated: animated, completion: completion)
    }

    // MARK: - ListSectionViewModelProtocol

    open class func canHandleData(_ data: Any?) -> Bool {
        false
    }

    open class func sectionViewModel(forData data: Any, context: ListContext) -> Self {
        fatalError("Subclass must override sectionViewModel(forData:context:)")
    }

    open func isEqual(toData data: Any) -> Bool {
        guard let model = responseModel else { return false }
        return (model as AnyObject) === (data as AnyObject)
    }

    // MARK: - IGListDiffable

    open func diffIdentifier() -> any NSObjectProtocol {
        return ObjectIdentifier(self) as AnyObject as! NSObjectProtocol
    }

    open func isEqual(toDiffableObject object: (any IGListKit.ListDiffable)?) -> Bool {
        return self === (object as AnyObject)
    }

    // MARK: - Helpers

    static func removeDuplicates(_ objects: [AnyObject]) -> [AnyObject] {
        var seen = Set<ObjectIdentifier>()
        return objects.filter { seen.insert(ObjectIdentifier($0)).inserted }
    }
}
