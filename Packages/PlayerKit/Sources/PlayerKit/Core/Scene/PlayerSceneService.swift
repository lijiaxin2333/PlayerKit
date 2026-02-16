import Foundation

@MainActor
public protocol PlayerSceneProtocol: AnyObject {

    var sceneId: String { get }

    var sceneType: String { get }

    var enginePool: PlayerEnginePoolService? { get }

    var isActive: Bool { get }
}

@MainActor
public protocol PlayerSceneManagerService: PluginService {

    var activeScenes: [PlayerSceneProtocol] { get }

    var currentScene: PlayerSceneProtocol? { get }

    func registerScene(_ scene: PlayerSceneProtocol)

    func unregisterScene(_ scene: PlayerSceneProtocol)

    func setCurrentScene(_ scene: PlayerSceneProtocol?)

    func scene(forId sceneId: String) -> PlayerSceneProtocol?
}
