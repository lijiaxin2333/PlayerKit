import Foundation

@MainActor
public struct PlayerTransferState {
    public var rate: Float
    public var volume: Float
    public var isLooping: Bool
    public var scalingMode: PlayerScalingMode
    public var currentTime: TimeInterval
    public var isPlaying: Bool

    public init(from engine: PlayerEngineCoreService) {
        self.rate = engine.rate
        self.volume = engine.volume
        self.isLooping = engine.isLooping
        self.scalingMode = engine.scalingMode
        self.currentTime = engine.currentTime
        self.isPlaying = engine.playbackState == .playing
    }

    public func apply(to engine: PlayerEngineCoreService) {
        engine.rate = rate
        engine.volume = volume
        engine.isLooping = isLooping
        engine.scalingMode = scalingMode
    }
}

@MainActor
public protocol PlayerSceneTransferService: PluginService {

    func transferEngine(
        from sourcePlayer: Player,
        to targetPlayer: Player,
        completion: ((Bool) -> Void)?
    )

    func detachEngine(from player: Player) -> PlayerEngineCoreService?

    func attachEngine(_ engine: PlayerEngineCoreService, to player: Player)

    func captureState(from player: Player) -> PlayerTransferState?

    func restoreState(_ state: PlayerTransferState, to player: Player)
}
