import Foundation
import PlayerKit

/**
 * 播放器场景播放流程插件
 * 协调播放准备、创建、挂载及播放控制的执行流程
 */
@MainActor
public final class ScenePlayerProcessPlugin: BasePlugin, ScenePlayerProcessService {

    @PlayerPlugin private var engineService: PlayerEngineCoreService?
    @PlayerPlugin private var playbackControl: PlayerPlaybackControlService?

    public required init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    private var hasPlayer: Bool {
        guard let holder = context?.holder as? ScenePlayerProtocol else { return false }
        return holder.hasPlayer()
    }

    // MARK: - PlayerScenePlayerProcessService

    /**
     * 执行播放流程
     * 根据是否有已创建的播放器及数据有效性，依次执行 prepare、createIfNeeded、attach 等步骤
     * - Parameters:
     *   - isAutoPlay: 是否自动开始播放
     *   - prepare: 播放前的准备回调
     *   - createIfNeeded: 若无播放器则创建的回调
     *   - attach: 挂载回调
     *   - checkDataValid: 检查数据有效性的回调，返回 true 表示有效
     *   - setDataIfNeeded: 数据无效时设置数据的回调
     */
    public func execPlay(
        isAutoPlay: Bool,
        prepare: (() -> Void)?,
        createIfNeeded: (() -> Void)?,
        attach: (() -> Void)?,
        checkDataValid: (() -> Bool)?,
        setDataIfNeeded: (() -> Void)?
    ) {
        if hasPlayer {
            let hasActiveEngine = engineService?.currentURL != nil
            if hasActiveEngine == true {
                if engineService?.playbackState == .playing {
                    return
                }
            }
            prepare?()
            if hasActiveEngine != true {
                createIfNeeded?()
            }
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

        if isAutoPlay {
            if let playbackControl = playbackControl, !playbackControl.isPlaying {
                playbackControl.play()
            }
        }
    }

    /**
     * 检查是否需要执行播放
     * 默认不重播已结束的播放
     * - Returns: true 表示需要执行播放
     */
    public func checkIfNeedExecPlay() -> Bool {
        return checkIfNeedExecPlay(replayWhenFinished: false)
    }

    /**
     * 检查是否需要执行播放
     * - Parameter replayWhenFinished: 播放已结束时是否允许重播
     * - Returns: true 表示需要执行播放
     */
    public func checkIfNeedExecPlay(replayWhenFinished: Bool) -> Bool {
        if hasPlayer {
            guard let engine = engineService else {
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
