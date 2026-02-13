import UIKit

@MainActor
public protocol ListSectionViewModelProtocol: AnyObject {

    static func canHandleData(_ data: Any?) -> Bool

    static func sectionViewModel(forData data: Any, context: ListContext) -> Self

    func sectionViewModelWillDisplay(duplicateReload: Bool)

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool)

    func sectionViewModelWillAppearByViewController()

    func sectionViewModelDidAppearByViewController()

    func sectionViewModelWillDisappearByViewController()

    func sectionViewModelDidDisappearByViewController()
}

public extension ListSectionViewModelProtocol {

    func sectionViewModelWillDisplay(duplicateReload: Bool) {}

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool) {}

    func sectionViewModelWillAppearByViewController() {}

    func sectionViewModelDidAppearByViewController() {}

    func sectionViewModelWillDisappearByViewController() {}

    func sectionViewModelDidDisappearByViewController() {}
}
