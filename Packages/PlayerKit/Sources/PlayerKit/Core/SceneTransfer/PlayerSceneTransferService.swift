import Foundation

/**
 * 播放器迁移状态，保存引擎的可迁移属性
 */
@MainActor
public struct PlayerTransferState {
    /** 播放速率 */
    public var rate: Float
    /** 音量 */
    public var volume: Float
    /** 是否循环播放 */
    public var isLooping: Bool
    /** 缩放模式 */
    public var scalingMode: PlayerScalingMode
    /** 当前播放时间 */
    public var currentTime: TimeInterval
    /** 是否正在播放 */
    public var isPlaying: Bool

    /**
     * 从引擎创建迁移状态
     */
    public init(from engine: PlayerEngineCoreService) {
        self.rate = engine.rate
        self.volume = engine.volume
        self.isLooping = engine.isLooping
        self.scalingMode = engine.scalingMode
        self.currentTime = engine.currentTime
        self.isPlaying = engine.playbackState == .playing
    }

    /**
     * 将状态应用到引擎
     */
    public func apply(to engine: PlayerEngineCoreService) {
        engine.rate = rate
        engine.volume = volume
        engine.isLooping = isLooping
        engine.scalingMode = scalingMode
    }
}

/**
 * 场景迁移服务协议
 */
@MainActor
public protocol PlayerSceneTransferService: PluginService {

    /**
     * 将引擎从源播放器迁移到目标播放器
     */
    func transferEngine(
        from sourcePlayer: Player,
        to targetPlayer: Player,
        completion: ((Bool) -> Void)?
    )

    /**
     * 从播放器上分离引擎
     */
    func detachEngine(from player: Player) -> PlayerEngineCoreService?

    /**
     * 将引擎附加到播放器
     */
    func attachEngine(_ engine: PlayerEngineCoreService, to player: Player)

    /**
     * 从播放器捕获迁移前的状态
     */
    func captureState(from player: Player) -> PlayerTransferState?

    /**
     * 将状态恢复到目标播放器的引擎
     */
    func restoreState(_ state: PlayerTransferState, to player: Player)
}
