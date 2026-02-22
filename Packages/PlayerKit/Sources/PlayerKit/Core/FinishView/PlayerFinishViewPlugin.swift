//
//  PlayerFinishViewPlugin.swift
//  playerkit
//
//  播放结束视图组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 播放结束视图

public class PlayerFinishView: UIView {
    private let backgroundView = UIView()
    private let replayButton = UIButton(type: .system)
    private let messageLabel = UILabel()

    public var replayAction: (() -> Void)?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.6)

        // 背景视图
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .black.withAlphaComponent(0.4)
        backgroundView.layer.cornerRadius = 12
        addSubview(backgroundView)

        // 消息标签
        messageLabel.text = "播放完成"
        messageLabel.textColor = .white
        messageLabel.font = .systemFont(ofSize: 18, weight: .medium)
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(messageLabel)

        // 重播按钮
        replayButton.setTitle("重播", for: .normal)
        replayButton.setTitleColor(.white, for: .normal)
        replayButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        replayButton.backgroundColor = .systemBlue
        replayButton.layer.cornerRadius = 8
        replayButton.translatesAutoresizingMaskIntoConstraints = false
        replayButton.addTarget(self, action: #selector(handleReplay), for: .touchUpInside)
        backgroundView.addSubview(replayButton)

        NSLayoutConstraint.activate([
            backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor),
            backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor),
            backgroundView.widthAnchor.constraint(equalToConstant: 200),
            backgroundView.heightAnchor.constraint(equalToConstant: 120),

            messageLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -20),

            replayButton.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
            replayButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -20),
            replayButton.widthAnchor.constraint(equalToConstant: 100),
            replayButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    @objc private func handleReplay() {
        replayAction?()
    }
}

// MARK: - 播放结束视图组件

@MainActor
public final class PlayerFinishViewPlugin: BasePlugin, PlayerFinishViewService {

    public typealias ConfigModelType = PlayerFinishViewConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?
    @PlayerPlugin private var playbackControlService: PlayerPlaybackControlService?

    private var finishView: PlayerFinishView?
    private var isShowing: Bool = false

    // MARK: - Initialization

    public required init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 监听播放完成事件
        self.context?.add(self, event: .playerPlaybackDidFinish) { [weak self] _, _ in
            if let config = self?.configModel as? PlayerFinishViewConfigModel,
               config.autoShow {
                self?.showFinishView()
            }
        }
    }

    // MARK: - PlayerFinishViewService

    public func showFinishView() {
        guard !isShowing,
              let playerView = engineService?.playerView else {
            return
        }

        let view = PlayerFinishView(frame: playerView.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        view.replayAction = { [weak self] in
            self?.playbackControlService?.replay()
            self?.hideFinishView()
        }

        playerView.addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: playerView.topAnchor),
            view.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
        ])

        finishView = view
        isShowing = true

        UIView.animate(withDuration: 0.3) {
            view.alpha = 1
        }

        print("[PlayerFinishViewPlugin] 显示结束视图")
    }

    public func hideFinishView() {
        guard isShowing, let view = finishView else { return }

        UIView.animate(withDuration: 0.3, animations: {
            view.alpha = 0
        }) { [weak self] _ in
            view.removeFromSuperview()
            self?.finishView = nil
            self?.isShowing = false
        }

        print("[PlayerFinishViewPlugin] 隐藏结束视图")
    }
}
