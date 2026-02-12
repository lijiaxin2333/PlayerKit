import Foundation

@MainActor
public final class PlayerScenePlayerProcessComp: CCLBaseComp, PlayerScenePlayerProcessService {

    public required override init() {
        super.init()
    }

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
    }

    // MARK: - PlayerScenePlayerProcessService

    public func execPlay(
        isAutoPlay: Bool,
        prepare: (() -> Void)?,
        createIfNeeded: (() -> Void)?,
        attach: (() -> Void)?,
        checkDataValid: (() -> Bool)?,
        setDataIfNeeded: (() -> Void)?
    ) {
        guard let layeredService = context?.resolveService(PlayerTypedPlayerLayeredService.self) else {
            return
        }

        if layeredService.hasPlayer {
            guard let playbackControl = context?.resolveService(PlayerPlaybackControlService.self) else {
                return
            }
            if playbackControl.isPaused {
                playbackControl.play()
                return
            }
            prepare?()
        } else {
            prepare?()
            createIfNeeded?()
        }

        var isDataValid = false
        if let checkDataValid = checkDataValid {
            isDataValid = checkDataValid()
        }

        if !isDataValid {
            setDataIfNeeded?()
        }

        attach?()

        guard let playbackControl = context?.resolveService(PlayerPlaybackControlService.self) else {
            return
        }
        if isAutoPlay {
            playbackControl.play()
        }
    }

    public func checkIfNeedExecPlay() -> Bool {
        return checkIfNeedExecPlay(replayWhenFinished: false)
    }

    public func checkIfNeedExecPlay(replayWhenFinished: Bool) -> Bool {
        guard let layeredService = context?.resolveService(PlayerTypedPlayerLayeredService.self) else {
            return true
        }

        if layeredService.hasPlayer {
            guard let engine = context?.resolveService(PlayerEngineCoreService.self) else {
                return true
            }
            if engine.playbackState == .playing {
                return false
            }
            if engine.playbackState == .stopped && !replayWhenFinished {
                return false
            }
        }

        return true
    }
}
