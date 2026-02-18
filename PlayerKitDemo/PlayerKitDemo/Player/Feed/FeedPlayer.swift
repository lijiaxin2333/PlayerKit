import Foundation
import UIKit
import PlayerKit

public class FeedPlayerConfiguration: NSObject {

    public var createForPreRender: Bool = false

    public var pluginBlackList: Set<String> = []

    public var prerenderKey: String?

    public var autoPlay: Bool = true

    public var looping: Bool = false

    public override init() {
        super.init()
    }
}

@MainActor
public final class FeedPlayer: ContextHolder, TypedPlayerProtocol {

    public let context: PublicContext

    private(set) var player: Player?
    private let configuration: FeedPlayerConfiguration

    public init(configuration: FeedPlayerConfiguration = FeedPlayerConfiguration()) {
        self.configuration = configuration
        let ctx = Context(name: "FeedPlayer")
        self.context = ctx
        setupPlayer()
    }

    public init(adoptingPlayer player: Player, configuration: FeedPlayerConfiguration = FeedPlayerConfiguration()) {
        self.configuration = configuration
        let ctx = Context(name: "FeedPlayer")
        self.context = ctx
        self.player = player

        ctx.addSubContext(
            player.context,
            buildBlock: { [weak self] subContext, superContext in
                guard let self = self else { return }
                let configModel = PlayerEngineCoreConfigModel()
                configModel.autoPlay = self.configuration.autoPlay
                configModel.isLooping = self.configuration.looping
                player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: configModel)
            }
        )
    }

    private func setupPlayer() {
        let player = Player(name: "FeedPlayer.Base.\(UUID().uuidString)")
        self.player = player

        (context as? Context)?.addSubContext(
            player.context,
            buildBlock: { [weak self] subContext, superContext in
                guard let self = self else { return }
                let configModel = PlayerEngineCoreConfigModel()
                configModel.autoPlay = self.configuration.autoPlay
                configModel.isLooping = self.configuration.looping
                player.context.configPlugin(serviceProtocol: PlayerEngineCoreService.self, withModel: configModel)
            }
        )
    }

    // MARK: - Engine Pool

    public func bindPool(_ pool: PlayerEnginePoolService, identifier: String) {
        player?.bindPool(pool, identifier: identifier)
    }

    @discardableResult
    public func acquireEngine() -> Bool {
        player?.acquireEngine() ?? false
    }

    public func recycleEngine() {
        player?.recycleEngine()
    }

    // MARK: - Service Access

    public var engineService: PlayerEngineCoreService? {
        context.resolveService(PlayerEngineCoreService.self)
    }

    public var dataService: PlayerDataService? {
        context.resolveService(PlayerDataService.self)
    }

    public var processService: PlayerProcessService? {
        context.resolveService(PlayerProcessService.self)
    }

    public var viewService: PlayerViewService? {
        context.resolveService(PlayerViewService.self)
    }

    public var speedService: PlayerSpeedService? {
        context.resolveService(PlayerSpeedService.self)
    }

    public var playbackControlService: PlayerPlaybackControlService? {
        context.resolveService(PlayerPlaybackControlService.self)
    }

    // MARK: - Public API

    public func play() {
        engineService?.play()
    }

    public func pause() {
        engineService?.pause()
    }

    public func stop() {
        engineService?.stop()
    }

    public func seek(to time: TimeInterval) {
        engineService?.seek(to: time)
    }

    public func setSpeed(_ speed: Float) {
        speedService?.setSpeed(speed)
    }

    public var playerView: UIView? {
        engineService?.playerView
    }

    public var isPlaying: Bool {
        engineService?.playbackState == .playing
    }

    // MARK: - Reuse Lifecycle

    public func willReusePlayer() {
        engineService?.pause()
    }

    public func didReusePlayer() {
    }

    public func willRecyclePlayer() {
        pause()
    }

    public func didRecyclePlayer() {
    }

    public func releasePlayer() {
        engineService?.pause()
    }

    public func destroyPlayer() {
        engineService?.pause()
        engineService?.replaceCurrentItem(with: nil)
    }

    // MARK: - Cleanup

    public func cleanup() {
        if let playerCtx = player?.context {
            context.removeSubContext(playerCtx)
        }
        player = nil
    }
}
