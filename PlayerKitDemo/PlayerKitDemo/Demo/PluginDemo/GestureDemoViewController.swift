import UIKit
import PlayerKit

@MainActor
final class GestureDemoViewController: PluginDemoBaseViewController {

    override var demoDescription: String {
        "演示手势交互功能：支持单击（显隐控制）、双击（播放/暂停）、左右滑动（快进快退）、上下滑动（亮度/音量）、捏合（缩放）、长按（加速播放）。在播放器区域操作即可触发。"
    }

    override var demoPlugins: [String] {
        ["PlayerGesturePlugin", "PlayerPlaybackControlPlugin", "PlayerProcessPlugin"]
    }

    private let gestureLog = UITextView()
    private var logLines: [String] = []
    private var handlers: [PlayerGestureHandler] = []

    override func onPlayerReady() {
        guard let gestureService = player.gestureService else { return }
        gestureService.gestureView = playerContainer

        let singleTap = DemoSingleTapHandler { [weak self] in self?.appendLog("👆 单击") }
        let doubleTap = DemoDoubleTapHandler { [weak self] in self?.appendLog("👆👆 双击") }
        let pan = DemoPanHandler { [weak self] msg in self?.appendLog(msg) }
        let longPress = DemoLongPressHandler { [weak self] msg in self?.appendLog(msg) }
        let pinch = DemoPinchHandler { [weak self] msg in self?.appendLog(msg) }

        handlers = [singleTap, doubleTap, pan, longPress, pinch]
        handlers.forEach { gestureService.addHandler($0) }

        let toggleRow = makeHStack()
        toggleRow.addArrangedSubview(makeActionButton(title: "启用/禁用手势", action: #selector(toggleGestures)))
        toggleRow.addArrangedSubview(makeActionButton(title: "清空日志", action: #selector(clearLog)))
        controlStack.addArrangedSubview(toggleRow)

        gestureLog.isEditable = false
        gestureLog.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        gestureLog.textColor = .secondaryLabel
        gestureLog.backgroundColor = .tertiarySystemBackground
        gestureLog.layer.cornerRadius = 8
        gestureLog.text = "手势事件日志...\n在播放器区域操作触发手势"
        gestureLog.translatesAutoresizingMaskIntoConstraints = false
        gestureLog.heightAnchor.constraint(equalToConstant: 150).isActive = true
        controlStack.addArrangedSubview(gestureLog)
    }

    private func appendLog(_ msg: String) {
        logLines.append(msg)
        if logLines.count > 50 { logLines.removeFirst() }
        gestureLog.text = logLines.joined(separator: "\n")
        if !gestureLog.text.isEmpty {
            let bottom = NSRange(location: gestureLog.text.count - 1, length: 1)
            gestureLog.scrollRangeToVisible(bottom)
        }
    }

    @objc private func toggleGestures() {
        guard let gs = player.gestureService else { return }
        gs.isEnabled.toggle()
        appendLog(gs.isEnabled ? "✅ 手势已启用" : "❌ 手势已禁用")
    }

    @objc private func clearLog() {
        logLines.removeAll()
        gestureLog.text = "手势事件日志..."
    }
}

// MARK: - Gesture Handlers

@MainActor
private final class DemoSingleTapHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .singleTap }
    let onTap: () -> Void
    init(onTap: @escaping () -> Void) { self.onTap = onTap }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) { onTap() }
}

@MainActor
private final class DemoDoubleTapHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .doubleTap }
    let onTap: () -> Void
    init(onTap: @escaping () -> Void) { self.onTap = onTap }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) { onTap() }
}

@MainActor
private final class DemoPanHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .pan }
    let onEvent: (String) -> Void
    init(onEvent: @escaping (String) -> Void) { self.onEvent = onEvent }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let pan = recognizer as? UIPanGestureRecognizer else { return }
        let dirStr: String
        switch direction {
        case .horizontal: dirStr = "水平"
        case .verticalLeft: dirStr = "左侧垂直"
        case .verticalRight: dirStr = "右侧垂直"
        default: dirStr = "未知"
        }
        switch pan.state {
        case .began: onEvent("✋ 滑动开始 - \(dirStr)")
        case .ended, .cancelled: onEvent("✋ 滑动结束 - \(dirStr)")
        default: break
        }
    }
}

@MainActor
private final class DemoLongPressHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .longPress }
    let onEvent: (String) -> Void
    init(onEvent: @escaping (String) -> Void) { self.onEvent = onEvent }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        switch recognizer.state {
        case .began: onEvent("✊ 长按开始")
        case .ended, .cancelled: onEvent("✊ 长按结束")
        default: break
        }
    }
}

@MainActor
private final class DemoPinchHandler: PlayerGestureHandler {
    var gestureType: PlayerGestureType { .pinch }
    let onEvent: (String) -> Void
    init(onEvent: @escaping (String) -> Void) { self.onEvent = onEvent }
    func handleGesture(_ recognizer: UIGestureRecognizer, direction: PlayerPanDirection) {
        guard let pinch = recognizer as? UIPinchGestureRecognizer else { return }
        if pinch.state == .ended {
            onEvent("🤏 捏合 scale=\(String(format: "%.2f", pinch.scale))")
        }
    }
}
