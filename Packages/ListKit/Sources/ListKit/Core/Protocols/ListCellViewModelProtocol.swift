import UIKit

@MainActor
public protocol ListCellViewModelProtocol: AnyObject {

    func cellClass() -> AnyClass

    func cellSize() -> CGSize

    func preferredCellSize() -> CGSize

    var isVisible: Bool { get set }

    func cellViewModelWillDisplay(duplicateReload: Bool)

    func cellViewModelDidEndDisplaying(duplicateReload: Bool)

    func cellViewModelWillAppearByViewController()

    func cellViewModelDidAppearByViewController()

    func cellViewModelWillDisappearByViewController()

    func cellViewModelDidDisappearByViewController()

    func sectionViewModelWillDisplay(duplicateReload: Bool)

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool)
}

public extension ListCellViewModelProtocol {

    func cellViewModelWillDisplay(duplicateReload: Bool) {}

    func cellViewModelDidEndDisplaying(duplicateReload: Bool) {}

    func cellViewModelWillAppearByViewController() {}

    func cellViewModelDidAppearByViewController() {}

    func cellViewModelWillDisappearByViewController() {}

    func cellViewModelDidDisappearByViewController() {}

    func sectionViewModelWillDisplay(duplicateReload: Bool) {}

    func sectionViewModelDidEndDisplaying(duplicateReload: Bool) {}
}
