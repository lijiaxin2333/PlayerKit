import Foundation
import BizPlayerKit

/**
 * 播放器场景播放流程服务协议
 * 定义播放流程执行及是否需要执行播放的检查能力
 */
@MainActor
public protocol ScenePlayerProcessService: PluginService {

    /**
     * 执行播放流程
     * 引擎获取由基础层 Player.ensureEngine() 自动完成（预渲染池优先，引擎池兜底）
     * - Parameters:
     *   - isAutoPlay: 是否自动开始播放
     *   - prepare: 播放前的准备回调
     *   - attach: 挂载回调
     *   - checkDataValid: 检查数据有效性的回调
     *   - setDataIfNeeded: 数据无效时设置数据的回调
     */
    func execPlay(
        isAutoPlay: Bool,
        prepare: (() -> Void)?,
        attach: (() -> Void)?,
        checkDataValid: (() -> Bool)?,
        setDataIfNeeded: (() -> Void)?
    )

    /**
     * 检查是否需要执行播放
     * - Returns: true 表示需要执行播放
     */
    func checkIfNeedExecPlay() -> Bool

    /**
     * 检查是否需要执行播放
     * - Parameter replayWhenFinished: 播放已结束时是否允许重播
     * - Returns: true 表示需要执行播放
     */
    func checkIfNeedExecPlay(replayWhenFinished: Bool) -> Bool
}
