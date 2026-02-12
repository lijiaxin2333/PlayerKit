import Foundation

@MainActor
public final class PlayerSceneManagerComp: CCLBaseComp, PlayerSceneManagerService {

    private var scenes: [String: PlayerSceneProtocol] = [:]
    private weak var _currentScene: (any PlayerSceneProtocol)?

    public var activeScenes: [PlayerSceneProtocol] {
        scenes.values.filter { $0.isActive }
    }

    public var currentScene: PlayerSceneProtocol? {
        _currentScene
    }

    public required override init() {
        super.init()
    }

    // MARK: - PlayerSceneManagerService

    public func registerScene(_ scene: PlayerSceneProtocol) {
        scenes[scene.sceneId] = scene
        context?.post(.playerSceneDidRegister, object: scene, sender: self)
    }

    public func unregisterScene(_ scene: PlayerSceneProtocol) {
        scenes.removeValue(forKey: scene.sceneId)
        if _currentScene?.sceneId == scene.sceneId {
            _currentScene = nil
        }
        context?.post(.playerSceneDidUnregister, object: scene, sender: self)
    }

    public func setCurrentScene(_ scene: PlayerSceneProtocol?) {
        _currentScene = scene
        context?.post(.playerSceneDidChange, object: scene, sender: self)
    }

    public func scene(forId sceneId: String) -> PlayerSceneProtocol? {
        scenes[sceneId]
    }
}
