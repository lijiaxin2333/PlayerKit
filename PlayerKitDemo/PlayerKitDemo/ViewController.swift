//
//  ViewController.swift
//  playerkit
//
//  简单的全屏视频播放器 - 用于调试基础能力
//

import UIKit
import PlayerKit

class ViewController: UIViewController {

    // MARK: - 播放器

    private let player: Player = Player(name: "DebugPlayer")

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("[ViewController] viewDidLoad")
        setupPlayer()
        setupUI()
        loadAndPlayVideo()
    }

    // MARK: - Setup

    private func setupPlayer() {
        // 确保引擎服务创建（触发 playerView 创建）
        _ = player.engineService
        print("[ViewController] Player setup complete")
    }

    private func setupUI() {
        view.backgroundColor = .black

        guard let playerView = player.engineService?.playerView else {
            print("[ViewController] ❌ playerView 为空!")
            return
        }

        playerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(playerView)

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        print("[ViewController] UI setup complete")
    }

    private func loadAndPlayVideo() {
        guard let url = Bundle.main.url(forResource: "onboarding_video_1", withExtension: "mp4") else {
            print("[ViewController] ❌ 找不到视频文件")
            return
        }

        print("[ViewController] 加载视频: \(url.lastPathComponent)")
        player.engineService?.setURL(url)
        player.engineService?.play()

        print("[ViewController] 开始播放")
    }
}
