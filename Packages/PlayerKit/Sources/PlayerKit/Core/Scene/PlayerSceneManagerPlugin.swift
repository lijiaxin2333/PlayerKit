import Foundation

/**
 * 播放器场景管理器插件
 * 负责场景的注册、注销以及当前场景的管理
 */
@MainActor
public final class PlayerSceneManagerPlugin: BasePlugin, PlayerSceneManagerService {

    /** 存储所有已注册的场景，key 为 sceneId */
    private var scenes: [String: PlayerSceneProtocol] = [:]
    /** 当前选中的场景的弱引用 */
    private weak var _currentScene: (any PlayerSceneProtocol)?

    /** 当前处于激活状态的所有场景列表 */
    public var activeScenes: [PlayerSceneProtocol] {
        scenes.values.filter { $0.isActive }
    }

    /** 当前选中的场景 */
    public var currentScene: PlayerSceneProtocol? {
        _currentScene
    }

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    // MARK: - PlayerSceneManagerService

    /**
     * 注册一个场景
     * - Parameter scene: 要注册的场景
     */
    public func registerScene(_ scene: PlayerSceneProtocol) {
        scenes[scene.sceneId] = scene
        context?.post(.playerSceneDidRegister, object: scene, sender: self)
    }

    /**
     * 注销一个场景
     * - Parameter scene: 要注销的场景
     */
    public func unregisterScene(_ scene: PlayerSceneProtocol) {
        scenes.removeValue(forKey: scene.sceneId)
        if _currentScene?.sceneId == scene.sceneId {
            _currentScene = nil
        }
        context?.post(.playerSceneDidUnregister, object: scene, sender: self)
    }

    /**
     * 设置当前场景
     * - Parameter scene: 要设为当前场景的场景，传 nil 表示清空当前场景
     */
    public func setCurrentScene(_ scene: PlayerSceneProtocol?) {
        _currentScene = scene
        context?.post(.playerSceneDidChange, object: scene, sender: self)
    }

    /**
     * 根据场景 ID 获取场景
     * - Parameter sceneId: 场景 ID
     * - Returns: 对应的场景，若不存在则返回 nil
     */
    public func scene(forId sceneId: String) -> PlayerSceneProtocol? {
        scenes[sceneId]
    }
}
