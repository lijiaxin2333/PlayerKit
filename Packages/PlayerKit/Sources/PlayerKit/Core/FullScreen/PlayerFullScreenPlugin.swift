//
//  PlayerFullScreenPlugin.swift
//  playerkit
//
//  全屏管理组件实现
//

import Foundation
import AVFoundation
import AVKit
import UIKit

@MainActor
public final class PlayerFullScreenPlugin: BasePlugin, PlayerFullScreenService {

    public typealias ConfigModelType = PlayerFullScreenConfigModel

    // MARK: - Properties

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _fullScreenState: PlayerFullScreenState = .normal
    private var _supportedOrientation: PlayerFullScreenOrientation = .auto
    private var fullScreenWindow: UIWindow?
    private var originalSuperview: UIView?
    private var originalFrame: CGRect = .zero
    private var playerViewController: AVPlayerViewController?

    // MARK: - PlayerFullScreenService

    public var fullScreenState: PlayerFullScreenState {
        get { _fullScreenState }
        set {
            guard _fullScreenState != newValue else { return }
            _fullScreenState = newValue
            context?.post(.playerFullScreenStateChanged, object: _fullScreenState, sender: self)
        }
    }

    public var isFullScreen: Bool {
        return fullScreenState == .fullScreen
    }

    public var supportedOrientation: PlayerFullScreenOrientation {
        get { _supportedOrientation }
        set { _supportedOrientation = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerFullScreenConfigModel else { return }

        supportedOrientation = config.supportedOrientation
    }

    // MARK: - Methods

    public func enterFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        guard fullScreenState != .fullScreen,
              let playerView = engineService?.playerView else {
            print("[PlayerFullScreenPlugin] 进入全屏失败: 播放器视图不可用")
            return
        }

        fullScreenState = .transitioning
        context?.post(.playerWillEnterFullScreen, sender: self)

        print("[PlayerFullScreenPlugin] 进入全屏, orientation: \(orientation)")

        // 保存原始状态
        originalSuperview = playerView.superview
        originalFrame = playerView.frame

        // 方案1: 使用 AVPlayerViewController (iOS原生全屏)
        if let avPlayer = engineService?.avPlayer {
            let playerVC = AVPlayerViewController()
            playerVC.player = avPlayer
            playerVC.showsPlaybackControls = false
            self.playerViewController = playerVC

            // 获取最顶层的 ViewController
            if let topVC = topViewController() {
                topVC.present(playerVC, animated: animated) { [weak self] in
                    guard let self = self else { return }
                    self.fullScreenState = .fullScreen
                    self.context?.post(.playerDidEnterFullScreen, sender: self)
                }
                return
            }
        }

        // 方案2: 使用全屏窗口
        createFullScreenWindow(with: playerView, animated: animated)

        fullScreenState = .fullScreen
        context?.post(.playerDidEnterFullScreen, sender: self)
    }

    public func exitFullScreen(animated: Bool = true) {
        guard fullScreenState != .normal else { return }

        fullScreenState = .transitioning
        context?.post(.playerWillExitFullScreen, sender: self)

        print("[PlayerFullScreenPlugin] 退出全屏")

        // 如果使用的是 AVPlayerViewController
        if let playerVC = playerViewController {
            playerVC.dismiss(animated: animated) { [weak self] in
                guard let self = self else { return }
                self.playerViewController = nil
                self.fullScreenState = .normal
                self.context?.post(.playerDidExitFullScreen, sender: self)
            }
            return
        }

        // 如果使用的是全屏窗口
        if let window = fullScreenWindow,
           let playerView = engineService?.playerView {
            // 恢复到原始父视图
            if let originalSuperview = originalSuperview {
                originalSuperview.addSubview(playerView)
                playerView.frame = originalFrame
            }

            // 隐藏并销毁全屏窗口
            window.isHidden = true
            fullScreenWindow = nil
        }

        fullScreenState = .normal
        context?.post(.playerDidExitFullScreen, sender: self)
    }

    public func toggleFullScreen(orientation: PlayerFullScreenOrientation = .auto, animated: Bool = true) {
        if isFullScreen {
            exitFullScreen(animated: animated)
        } else {
            enterFullScreen(orientation: orientation, animated: animated)
        }
    }

    // MARK: - Private Methods

    private func createFullScreenWindow(with playerView: UIView, animated: Bool) {
        let window: UIWindow

        if #available(iOS 13.0, *) {
            let scene = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first ?? UIApplication.shared.windows.first?.windowScene

            if let scene = scene {
                window = UIWindow(windowScene: scene)
            } else {
                window = UIWindow(frame: UIScreen.main.bounds)
            }
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
        }

        window.windowLevel = .statusBar + 1
        window.backgroundColor = .black

        // 创建容器视图
        let containerView = UIView(frame: window.bounds)
        containerView.backgroundColor = .black
        window.addSubview(containerView)

        // 移动播放器视图到全屏窗口
        playerView.removeFromSuperview()
        playerView.frame = containerView.bounds
        containerView.addSubview(playerView)

        // 显示窗口
        window.makeKeyAndVisible()
        fullScreenWindow = window

        print("[PlayerFullScreenPlugin] 创建全屏窗口: \(window.bounds)")
    }

    private func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
        let base = base ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
