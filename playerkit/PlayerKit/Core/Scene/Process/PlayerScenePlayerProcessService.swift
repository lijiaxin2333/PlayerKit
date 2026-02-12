import Foundation

@MainActor
public protocol PlayerScenePlayerProcessService: CCLCompService {

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
