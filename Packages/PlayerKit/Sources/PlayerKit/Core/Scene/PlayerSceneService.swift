import Foundation

/**
 * 播放器场景协议
 * 定义场景的基本属性和能力
 */
@MainActor
public protocol PlayerSceneProtocol: AnyObject {

    /** 场景的唯一标识 */
    var sceneId: String { get }

    /** 场景类型 */
    var sceneType: String { get }

    /** 当前场景是否处于激活状态 */
    var isActive: Bool { get }
}

/**
 * 播放器场景管理服务协议
 * 提供场景注册、注销及当前场景管理能力
 */
@MainActor
public protocol PlayerSceneManagerService: PluginService {

    /** 当前处于激活状态的所有场景列表 */
    var activeScenes: [PlayerSceneProtocol] { get }

    /** 当前选中的场景 */
    var currentScene: PlayerSceneProtocol? { get }

    /**
     * 注册一个场景
     * - Parameter scene: 要注册的场景
     */
    func registerScene(_ scene: PlayerSceneProtocol)

    /**
     * 注销一个场景
     * - Parameter scene: 要注销的场景
     */
    func unregisterScene(_ scene: PlayerSceneProtocol)

    /**
     * 设置当前场景
     * - Parameter scene: 要设为当前场景的场景，传 nil 表示清空当前场景
     */
    func setCurrentScene(_ scene: PlayerSceneProtocol?)

    /**
     * 根据场景 ID 获取场景
     * - Parameter sceneId: 场景 ID
     * - Returns: 对应的场景，若不存在则返回 nil
     */
    func scene(forId sceneId: String) -> PlayerSceneProtocol?
}
