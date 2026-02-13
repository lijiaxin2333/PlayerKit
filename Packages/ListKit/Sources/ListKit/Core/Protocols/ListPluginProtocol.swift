import UIKit

@MainActor
public protocol ListPluginProtocol: ListProtocol {

    var listContext: ListContext? { get set }

    func listContextDidLoad()

    func implementProtocols() -> [Any.Type]

    func dependencyProtocols() -> [Any.Type]
}

public extension ListPluginProtocol {

    func listContextDidLoad() {}

    func implementProtocols() -> [Any.Type] { [] }

    func dependencyProtocols() -> [Any.Type] { [] }
}
