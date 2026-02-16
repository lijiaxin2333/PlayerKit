import Foundation

@MainActor
public protocol PlayerScenePlayerProcessService: PluginService {

    func execPlay(
        isAutoPlay: Bool,
        prepare: (() -> Void)?,
        createIfNeeded: (() -> Void)?,
        attach: (() -> Void)?,
        checkDataValid: (() -> Bool)?,
        setDataIfNeeded: (() -> Void)?
    )

    func checkIfNeedExecPlay() -> Bool

    func checkIfNeedExecPlay(replayWhenFinished: Bool) -> Bool
}
