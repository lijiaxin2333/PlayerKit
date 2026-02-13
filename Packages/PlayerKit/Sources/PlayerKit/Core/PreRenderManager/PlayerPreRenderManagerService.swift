import Foundation

public enum PreRenderState: Int {
    case idle = 0
    case preparing
    case readyToDisplay
    case readyToPlay
    case failed
    case cancelled
    case expired
}

public struct PreRenderEntry {
    public let url: URL
    public let identifier: String
    public var state: PreRenderState
    public var player: Player?
    public var createTime: Date

    public init(url: URL, identifier: String) {
        self.url = url
        self.identifier = identifier
        self.state = .idle
        self.player = nil
        self.createTime = Date()
    }
}

@MainActor
public class PlayerPreRenderManagerConfigModel {
    public weak var enginePool: (any PlayerEnginePoolService)?
    public let poolIdentifier: String

    public init(enginePool: PlayerEnginePoolService, poolIdentifier: String = "default") {
        self.enginePool = enginePool
        self.poolIdentifier = poolIdentifier
    }
}

@MainActor
public protocol PlayerPreRenderManagerService: CCLCompService {

    var maxPreRenderCount: Int { get set }

    var preRenderTimeout: TimeInterval { get set }

    var activeEntries: [PreRenderEntry] { get }

    func preRender(url: URL, identifier: String)

    func preRender(urls: [(url: URL, identifier: String)])

    func cancelPreRender(identifier: String)

    func cancelAll()

    func consumePreRendered(identifier: String) -> Player?

    func takePlayer(identifier: String) -> Player?

    func isPreRendered(identifier: String) -> Bool

    func state(for identifier: String) -> PreRenderState
}
