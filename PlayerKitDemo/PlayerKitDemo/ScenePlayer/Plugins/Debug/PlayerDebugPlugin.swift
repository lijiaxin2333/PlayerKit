//
//  PlayerDebugPlugin.swift
//  playerkit
//
//  调试组件实现
//

import Foundation

import UIKit
import BizPlayerKit

// MARK: - 调试面板视图

private class PlayerDebugPanelView: UIView {
    private let contentView = UIView()
    private let closeButton = UIButton(type: .system)
    private let textView = UITextView()
    private var logMessages: [String] = []
    private let maxMessages = 100

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .clear

        // 内容视图
        contentView.backgroundColor = .black.withAlphaComponent(0.9)
        contentView.layer.cornerRadius = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        // 关闭按钮
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(handleClose), for: .touchUpInside)
        contentView.addSubview(closeButton)

        // 文本视图
        textView.backgroundColor = .clear
        textView.textColor = .green
        textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 50),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            closeButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),

            textView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 10),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    @objc private func handleClose() {
        removeFromSuperview()
    }

    func addLog(_ message: String) {
        let timestamp = DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        logMessages.append(logMessage)

        if logMessages.count > maxMessages {
            logMessages.removeFirst()
        }

        textView.text = logMessages.joined(separator: "\n")

        // 滚动到底部
        if textView.textStorage.length > 0 {
            textView.scrollRangeToVisible(NSRange(location: textView.textStorage.length - 1, length: 1))
        }
    }

}

// MARK: - 调试组件

@MainActor
public final class PlayerDebugPlugin: BasePlugin, PlayerDebugService {

    public typealias ConfigModelType = PlayerDebugConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _isDebugEnabled: Bool = false
    private var debugPanel: PlayerDebugPanelView?

    // MARK: - PlayerDebugService

    public var isDebugEnabled: Bool {
        get { _isDebugEnabled }
        set {
            _isDebugEnabled = newValue
            if newValue {
                showDebugPanel()
            } else {
                hideDebugPanel()
            }
        }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 定期更新调试信息
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateDebugInfo()
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerDebugConfigModel else { return }
        _isDebugEnabled = config.enabled

        if _isDebugEnabled && config.showDebugPanel {
            showDebugPanel()
        }
    }

    // MARK: - PlayerDebugService

    public func log(_ message: String, level: PlayerLogLevel = .info) {
        guard let config = configModel as? PlayerDebugConfigModel,
              level.rawValue >= config.logLevel.rawValue else { return }

        let prefix = level.prefix
        let formattedMessage = "[PlayerDebug\(prefix)] \(message)"

        debugPanel?.addLog(formattedMessage)
        print(formattedMessage)
    }

    public func showDebugPanel() {
        guard let playerView = engineService?.playerView,
              debugPanel == nil else { return }

        let panel = PlayerDebugPanelView(frame: playerView.bounds)
        panel.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(panel)

        NSLayoutConstraint.activate([
            panel.topAnchor.constraint(equalTo: playerView.topAnchor),
            panel.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
        ])

        debugPanel = panel
        log("调试面板已显示", level: .info)

        // 添加双击手势关闭
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        tapGesture.numberOfTapsRequired = 2
        panel.addGestureRecognizer(tapGesture)
    }

    public func hideDebugPanel() {
        debugPanel?.removeFromSuperview()
        debugPanel = nil
        log("调试面板已隐藏", level: .info)
    }

    // MARK: - Private Methods

    @objc private func handleDoubleTap() {
        hideDebugPanel()
    }

    private func updateDebugInfo() {
        guard _isDebugEnabled, let engine = engineService else { return }

        let state: String
        switch engine.playbackState {
        case .stopped: state = "stopped"
        case .playing: state = "playing"
        case .paused: state = "paused"
        case .seeking: state = "seeking"
        case .failed: state = "failed"
        }

        let currentTime = engine.currentTime
        let duration = engine.duration
        let bufferProgress = engine.bufferProgress

        let info = String(format: "状态: %@ | 时间: %.1fs / %.1fs | 缓冲: %.1f%%",
                        state, currentTime, duration, bufferProgress * 100)

        debugPanel?.addLog(info)
    }
}

// MARK: - PlayerLogLevel Extension

private extension PlayerLogLevel {
    var prefix: String {
        switch self {
        case .verbose: return "V"
        case .debug: return "D"
        case .info: return "I"
        case .warning: return "W"
        case .error: return "E"
        }
    }
}
