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
     * 引擎获取由基础层 Player.ensureEngine() 自动完成（预渲染池优先，引擎池兜底）
     * - Parameters:
     *   - isAutoPlay: 是否自动开始播放
     *   - prepare: 播放前的准备回调
     *   - attach: 挂载回调
     *   - checkDataValid: 检查数据有效性的回调，返回 true 表示有效
     *   - setDataIfNeeded: 数据无效时设置数据的回调
     */
    public func execPlay(
        isAutoPlay: Bool,
        prepare: (() -> Void)?,
        attach: (() -> Void)?,
        checkDataValid: (() -> Bool)?,
        setDataIfNeeded: (() -> Void)?
    ) {
        let holder = context?.holder as? ScenePlayerProtocol

        if hasPlayer {
            let hasActiveEngine = engineService?.avPlayer?.currentItem != nil
            if hasActiveEngine == true {
                if engineService?.playbackState == .playing {
                    return
                }
            }
            prepare?()
            if hasActiveEngine != true {
                holder?.player?.ensureEngine()
            }
        } else {
            prepare?()
            // 无播放器时，通过场景协议创建
            if let holder = holder {
                let player = holder.createPlayer(prerenderKey: nil)
                holder.addPlayer(player)
                player.ensureEngine()
            }
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
