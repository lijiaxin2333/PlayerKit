import os
import Foundation

@MainActor
public enum PLog {
    private static let logger = Logger(subsystem: "com.playerkit", category: "PlayerPipeline")
    private static let logPath = "/Users/mac/Documents/work/.cursor/debug.log"
    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private static var cellVisibleTime: [Int: CFAbsoluteTime] = [:]

    private static var ts: String { fmt.string(from: Date()) }

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

    public static func markCellVisible(_ index: Int) {
        cellVisibleTime[index] = CFAbsoluteTimeGetCurrent()
    }

    public static func clearCellVisibleCache() {
        cellVisibleTime.removeAll()
    }

    private static func cellToPlayMs(_ index: Int) -> Int {
        guard let t = cellVisibleTime[index] else { return -1 }
        return Int((CFAbsoluteTimeGetCurrent() - t) * 1000)
    }

    public static func obtain(_ index: Int, source: String, poolCount: Int, playersAlive: [Int]) {
        write("OBTAIN", ["idx": index, "src": source, "pool": poolCount, "alive": playersAlive.sorted().description])
    }

    public static func play(_ index: Int, needsSetURL: Bool, isReadyForDisplay: Bool, currentURL: String, playerViewFrame: String, playerViewInHierarchy: Bool) {
        let c2p = cellToPlayMs(index)
        write("PLAY", ["idx": index, "setURL": needsSetURL, "rfd": isReadyForDisplay, "url": String(currentURL.suffix(40)), "pvFrame": playerViewFrame, "pvInH": playerViewInHierarchy, "cellToPlay": c2p])
    }

    public static func evict(_ indices: [Int], poolCountAfter: Int) {
        guard !indices.isEmpty else { return }
        write("EVICT", ["idx": indices.sorted().description, "pool_after": poolCountAfter])
    }

    public static func preRenderStart(_ id: String, activeCount: Int) {
        write("PR_START", ["id": id, "active": activeCount])
    }

    public static func preRenderCancel(_ id: String, reason: String) {
        write("PR_CANCEL", ["id": id, "reason": reason])
    }

    public static func preRenderReadyToPlay(_ id: String, elapsedMs: Int) {
        write("PR_READY_PLAY", ["id": id, "elapsed": elapsedMs])
    }

    public static func preRenderReadyForDisplay(_ id: String, elapsedMs: Int) {
        write("PR_READY_DISPLAY", ["id": id, "elapsed": elapsedMs])
    }

    public static func preRenderConsume(_ id: String, state: String) {
        write("PR_CONSUME", ["id": id, "state": state])
    }

    public static func preRenderTake(_ id: String, state: String) {
        write("PR_TAKE", ["id": id, "state": state])
    }

    public static func preRenderSkip(_ id: String, reason: String) {
        write("PR_SKIP", ["id": id, "reason": reason])
    }

    public static func poolEnqueue(_ id: String, countAfter: Int) {
        write("POOL_ENQ", ["id": id, "count": countAfter])
    }

    public static func poolDequeue(_ id: String, hit: Bool, countAfter: Int) {
        write("POOL_DEQ", ["id": id, "hit": hit, "count": countAfter])
    }

    public static func engineSetURL(_ url: String, playerName: String) {
        write("ENGINE_SET_URL", ["url": String(url.suffix(40)), "player": playerName])
    }

    public static func engineReadyToPlay(elapsedMs: Int, playerName: String) {
        write("ENGINE_READY_PLAY", ["elapsed": elapsedMs, "player": playerName])
    }

    public static func engineReadyForDisplay(elapsedMs: Int, playerName: String) {
        write("ENGINE_READY_DISPLAY", ["elapsed": elapsedMs, "player": playerName])
    }

    public static func scrollPrepare(_ index: Int) {
        write("SCROLL_PREPARE", ["idx": index])
    }

    public static func scrollPlay(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("SCROLL_PLAY", ["idx": index, "cellToPlay": c2p])
    }

    public static func coverFadeOut(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("COVER_FADEOUT", ["idx": index, "cellToPlay": c2p])
    }

    public static func attachPlayer(_ index: Int, hasFirstFrame: Bool, coverHidden: Bool, playerViewFrame: String) {
        write("ATTACH", ["idx": index, "rfd": hasFirstFrame, "coverHidden": coverHidden, "pvFrame": playerViewFrame])
    }

    public static func upgrade(_ playerName: String, hadEngine: Bool, rfdBefore: Bool, rfdAfter: Bool) {
        write("UPGRADE", ["player": playerName, "hadEngine": hadEngine, "rfdBefore": rfdBefore, "rfdAfter": rfdAfter])
    }

    public static func playResume(_ index: Int, avPlayerRate: Float, avPlayerStatus: String) {
        write("PLAY_RESUME", ["idx": index, "rate": avPlayerRate, "status": avPlayerStatus])
    }

    public static func cellCoverState(_ index: Int, coverAlpha: Double, coverHidden: Bool, coverHasImage: Bool, playerViewFrame: String) {
        write("CELL_COVER_STATE", ["idx": index, "coverAlpha": coverAlpha, "coverHidden": coverHidden, "coverHasImage": coverHasImage, "pvFrame": playerViewFrame])
    }

    public static func renderViewState(_ index: Int, playerName: String, renderViewHidden: Bool, renderViewAlpha: Double, renderViewFrame: String, layerRFD: Bool, hasCurrentItem: Bool, avPlayerRate: Float) {
        write("RENDER_STATE", ["idx": index, "player": playerName, "rvHidden": renderViewHidden, "rvAlpha": renderViewAlpha, "rvFrame": renderViewFrame, "layerRFD": layerRFD, "hasItem": hasCurrentItem, "rate": avPlayerRate])
    }

    public static func viewHierarchy(_ index: Int, containerSubviewCount: Int, subviewDescriptions: String) {
        write("VIEW_HIERARCHY", ["idx": index, "subviewCount": containerSubviewCount, "subviews": subviewDescriptions])
    }

    public static func prepareForReuse(_ index: Int) {
        write("CELL_REUSE", ["idx": index])
    }

    public static func cellForItem(_ index: Int, hasPreRendered: Bool) {
        write("CELL_FOR_ITEM", ["idx": index, "hasPR": hasPreRendered])
    }

    public static func willDisplayCell(_ index: Int, hasPlayer: Bool) {
        markCellVisible(index)
        write("WILL_DISPLAY", ["idx": index, "hasPlayer": hasPlayer])
    }

    public static func detachPlayerLog(_ index: Int) {
        write("DETACH", ["idx": index])
    }

    public static func preRenderPauseState(_ id: String, avRate: Float, layerRFD: Bool, timeControlStatus: String) {
        write("PR_PAUSE_STATE", ["id": id, "rate": avRate, "layerRFD": layerRFD, "timeCtrl": timeControlStatus])
    }

    public static func firstFrameVisible(_ index: Int) {
        let c2p = cellToPlayMs(index)
        write("FIRST_FRAME_VISIBLE", ["idx": index, "cellToFirstFrame": c2p])
    }

    public static func delayedPlayCheck(_ index: Int, rate: Float, timeCtrl: Int, rfd: Bool, currentTime: Double, rvFrame: String) {
        write("PLAY_CHECK_100ms", ["idx": index, "rate": rate, "timeCtrl": timeCtrl, "rfd": rfd, "t": String(format: "%.2f", currentTime), "rvFrame": rvFrame])
    }

    public static func delayedPlayCheck300(_ index: Int, rate: Float, timeCtrl: Int, rfd: Bool, currentTime: Double) {
        write("PLAY_CHECK_300ms", ["idx": index, "rate": rate, "timeCtrl": timeCtrl, "rfd": rfd, "t": String(format: "%.2f", currentTime)])
    }

    public static func bufferResume(_ playerName: String, source: String, buffered: Double, keepUp: Bool) {
        write("BUFFER_RESUME", ["player": playerName, "source": source, "buffered": String(format: "%.2f", buffered), "keepUp": keepUp])
    }

    public static func bufferEmpty(_ playerName: String) {
        write("BUFFER_EMPTY", ["player": playerName])
    }

    public static func itemFailed(_ playerName: String, error: String) {
        write("ITEM_FAILED", ["player": playerName, "error": error])
    }

    public static func itemRetry(_ playerName: String) {
        write("ITEM_RETRY", ["player": playerName])
    }

}
