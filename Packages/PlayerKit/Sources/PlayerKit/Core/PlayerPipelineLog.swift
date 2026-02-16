import os
import Foundation

/**
 * 播放管线日志工具，用于调试和追踪播放器生命周期
 */
@MainActor
public enum PLog {
    /**
     * os.Logger 实例
     */
    private static let logger = Logger(subsystem: "com.playerkit", category: "PlayerPipeline")
    /**
     * 日志文件路径
     */
    private static let logPath = "/Users/mac/Documents/work/.cursor/debug.log"
    /**
     * 日期格式化器
     */
    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    /**
     * Cell 可见时间缓存（索引 -> 时间戳）
     */
    private static var cellVisibleTime: [Int: CFAbsoluteTime] = [:]

    /**
     * 当前时间戳字符串
     */
    private static var ts: String { fmt.string(from: Date()) }

    /**
     * 写入日志到控制台和文件
     */
    private static func write(_ event: String, _ data: [String: Any] = [:]) {
        let now = ts
        var payload: [String: Any] = [
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
            "ts": now,
            "event": event,
            "location": "PlayerPipeline"
        ]
        for (k, v) in data { payload[k] = v }
        let msg = "[\(now)] \(event) \(data.map { "\($0.key)=\($0.value)" }.joined(separator: " "))"
        logger.info("\(msg)")
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload),
           let jsonStr = String(data: jsonData, encoding: .utf8) {
            let line = jsonStr + "\n"
            if let fh = FileHandle(forWritingAtPath: logPath) {
                fh.seekToEndOfFile()
                fh.write(line.data(using: .utf8)!)
                fh.closeFile()
            } else {
                FileManager.default.createFile(atPath: logPath, contents: line.data(using: .utf8))
            }
        }
    }

    /**
     * 标记 Cell 可见
     */
    public static func markCellVisible(_ index: Int) {
        cellVisibleTime[index] = CFAbsoluteTimeGetCurrent()
    }

    /**
     * 清空 Cell 可见缓存
     */
    public static func clearCellVisibleCache() {
        cellVisibleTime.removeAll()
    }

    /**
     * 计算从 Cell 可见到播放的毫秒数
     */
    private static func cellToPlayMs(_ index: Int) -> Int {
        guard let t = cellVisibleTime[index] else { return -1 }
        return Int((CFAbsoluteTimeGetCurrent() - t) * 1000)
    }

    /**
     * 记录获取播放器
     */
    public static func obtain(_ index: Int, source: String, poolCount: Int, playersAlive: [Int]) {
        write("OBTAIN", ["idx": index, "src": source, "pool": poolCount, "alive": playersAlive.sorted().description])
    }

    /**
     * 记录播放
     */
    public static func play(_ index: Int, needsSetURL: Bool, isReadyForDisplay: Bool, currentURL: String, playerViewFrame: String, playerViewInHierarchy: Bool) {
        let c2p = cellToPlayMs(index)
        write("PLAY", ["idx": index, "setURL": needsSetURL, "rfd": isReadyForDisplay, "url": String(currentURL.suffix(40)), "pvFrame": playerViewFrame, "pvInH": playerViewInHierarchy, "cellToPlay": c2p])
    }

    /**
     * 记录驱逐
     */
    public static func evict(_ indices: [Int], poolCountAfter: Int) {
        guard !indices.isEmpty else { return }
        write("EVICT", ["idx": indices.sorted().description, "pool_after": poolCountAfter])
    }

    /**
     * 记录预渲染开始
     */
    public static func preRenderStart(_ id: String, activeCount: Int) {
        write("PR_START", ["id": id, "active": activeCount])
    }

    /**
     * 记录预渲染取消
     */
    public static func preRenderCancel(_ id: String, reason: String) {
        write("PR_CANCEL", ["id": id, "reason": reason])
    }

    /**
     * 记录预渲染就绪可播放
     */
    public static func preRenderReadyToPlay(_ id: String, elapsedMs: Int) {
        write("PR_READY_PLAY", ["id": id, "elapsed": elapsedMs])
    }

    /**
     * 记录预渲染就绪可显示
     */
    public static func preRenderReadyForDisplay(_ id: String, elapsedMs: Int) {
        write("PR_READY_DISPLAY", ["id": id, "elapsed": elapsedMs])
    }

    /**
     * 记录预渲染消费
     */
    public static func preRenderConsume(_ id: String, state: String) {
        write("PR_CONSUME", ["id": id, "state": state])
    }

    /**
     * 记录预渲染获取
     */
    public static func preRenderTake(_ id: String, state: String) {
        write("PR_TAKE", ["id": id, "state": state])
    }

    /**
     * 记录预渲染跳过
     */
    public static func preRenderSkip(_ id: String, reason: String) {
        write("PR_SKIP", ["id": id, "reason": reason])
    }

    /**
     * 记录入队回收池
     */
    public static func poolEnqueue(_ id: String, countAfter: Int) {
        write("POOL_ENQ", ["id": id, "count": countAfter])
    }

    /**
     * 记录从回收池出队
     */
    public static func poolDequeue(_ id: String, hit: Bool, countAfter: Int) {
        write("POOL_DEQ", ["id": id, "hit": hit, "count": countAfter])
    }

    /**
     * 记录引擎设置 URL
     */
    public static func engineSetURL(_ url: String, playerName: String) {
        write("ENGINE_SET_URL", ["url": String(url.suffix(40)), "player": playerName])
    }

    /**
     * 记录引擎就绪可播放
     */
    public static func engineReadyToPlay(elapsedMs: Int, playerName: String) {
        write("ENGINE_READY_PLAY", ["elapsed": elapsedMs, "player": playerName])
    }

    /**
     * 记录引擎就绪可显示
     */
    public static func engineReadyForDisplay(elapsedMs: Int, playerName: String) {
        write("ENGINE_READY_DISPLAY", ["elapsed": elapsedMs, "player": playerName])
    }

    /**
     * 记录滚动准备
     */
    public static func scrollPrepare(_ index: Int) {
        write("SCROLL_PREPARE", ["idx": index])
    }

    /**
     * 记录滚动播放
     */
    public static func scrollPlay(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("SCROLL_PLAY", ["idx": index, "cellToPlay": c2p])
    }

    /**
     * 记录封面淡出
     */
    public static func coverFadeOut(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("COVER_FADEOUT", ["idx": index, "cellToPlay": c2p])
    }

    /**
     * 记录附加播放器
     */
    public static func attachPlayer(_ index: Int, hasFirstFrame: Bool, coverHidden: Bool, playerViewFrame: String) {
        write("ATTACH", ["idx": index, "rfd": hasFirstFrame, "coverHidden": coverHidden, "pvFrame": playerViewFrame])
    }

    /**
     * 记录升级
     */
    public static func upgrade(_ playerName: String, hadEngine: Bool, rfdBefore: Bool, rfdAfter: Bool) {
        write("UPGRADE", ["player": playerName, "hadEngine": hadEngine, "rfdBefore": rfdBefore, "rfdAfter": rfdAfter])
    }

    /**
     * 记录播放恢复
     */
    public static func playResume(_ index: Int, avPlayerRate: Float, avPlayerStatus: String) {
        write("PLAY_RESUME", ["idx": index, "rate": avPlayerRate, "status": avPlayerStatus])
    }

    /**
     * 记录 Cell 封面状态
     */
    public static func cellCoverState(_ index: Int, coverAlpha: Double, coverHidden: Bool, coverHasImage: Bool, playerViewFrame: String) {
        write("CELL_COVER_STATE", ["idx": index, "coverAlpha": coverAlpha, "coverHidden": coverHidden, "coverHasImage": coverHasImage, "pvFrame": playerViewFrame])
    }

    /**
     * 记录渲染视图状态
     */
    public static func renderViewState(_ index: Int, playerName: String, renderViewHidden: Bool, renderViewAlpha: Double, renderViewFrame: String, layerRFD: Bool, hasCurrentItem: Bool, avPlayerRate: Float) {
        write("RENDER_STATE", ["idx": index, "player": playerName, "rvHidden": renderViewHidden, "rvAlpha": renderViewAlpha, "rvFrame": renderViewFrame, "layerRFD": layerRFD, "hasItem": hasCurrentItem, "rate": avPlayerRate])
    }

    /**
     * 记录视图层级
     */
    public static func viewHierarchy(_ index: Int, containerSubviewCount: Int, subviewDescriptions: String) {
        write("VIEW_HIERARCHY", ["idx": index, "subviewCount": containerSubviewCount, "subviews": subviewDescriptions])
    }

    /**
     * 记录准备复用
     */
    public static func prepareForReuse(_ index: Int) {
        write("CELL_REUSE", ["idx": index])
    }

    /**
     * 记录 cellForItem
     */
    public static func cellForItem(_ index: Int, hasPreRendered: Bool) {
        write("CELL_FOR_ITEM", ["idx": index, "hasPR": hasPreRendered])
    }

    /**
     * 记录 willDisplayCell
     */
    public static func willDisplayCell(_ index: Int, hasPlayer: Bool) {
        markCellVisible(index)
        write("WILL_DISPLAY", ["idx": index, "hasPlayer": hasPlayer])
    }

    /**
     * 记录分离播放器
     */
    public static func detachPlayerLog(_ index: Int) {
        write("DETACH", ["idx": index])
    }

    /**
     * 记录预渲染暂停状态
     */
    public static func preRenderPauseState(_ id: String, avRate: Float, layerRFD: Bool, timeControlStatus: String) {
        write("PR_PAUSE_STATE", ["id": id, "rate": avRate, "layerRFD": layerRFD, "timeCtrl": timeControlStatus])
    }

    /**
     * 记录首帧可见
     */
    public static func firstFrameVisible(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("FIRST_FRAME_VISIBLE", ["idx": index, "cellToFirstFrame": c2p])
    }

    /**
     * 记录延迟播放检查（100ms）
     */
    public static func delayedPlayCheck(_ index: Int, rate: Float, timeCtrl: Int, rfd: Bool, currentTime: Double, rvFrame: String) {
        write("PLAY_CHECK_100ms", ["idx": index, "rate": rate, "timeCtrl": timeCtrl, "rfd": rfd, "t": String(format: "%.2f", currentTime), "rvFrame": rvFrame])
    }

    /**
     * 记录延迟播放检查（300ms）
     */
    public static func delayedPlayCheck300(_ index: Int, rate: Float, timeCtrl: Int, rfd: Bool, currentTime: Double) {
        write("PLAY_CHECK_300ms", ["idx": index, "rate": rate, "timeCtrl": timeCtrl, "rfd": rfd, "t": String(format: "%.2f", currentTime)])
    }

    /**
     * 记录缓冲恢复
     */
    public static func bufferResume(_ playerName: String, source: String, buffered: Double, keepUp: Bool) {
        write("BUFFER_RESUME", ["player": playerName, "source": source, "buffered": String(format: "%.2f", buffered), "keepUp": keepUp])
    }

    /**
     * 记录缓冲为空
     */
    public static func bufferEmpty(_ playerName: String) {
        write("BUFFER_EMPTY", ["player": playerName])
    }

    /**
     * 记录 Item 失败
     */
    public static func itemFailed(_ playerName: String, error: String) {
        write("ITEM_FAILED", ["player": playerName, "error": error])
    }

    /**
     * 记录 Item 重试
     */
    public static func itemRetry(_ playerName: String) {
        write("ITEM_RETRY", ["player": playerName])
    }

}
