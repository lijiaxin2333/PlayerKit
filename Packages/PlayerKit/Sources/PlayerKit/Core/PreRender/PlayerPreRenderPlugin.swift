import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerPreRenderPlugin: BasePlugin, PlayerPreRenderService {

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _state: PlayerPreRenderState = .idle
    private var _isPrerenderPlaying: Bool = false
    private var playerContainerView: UIView?

    public var preRenderState: PlayerPreRenderState { _state }

    public var isPrerenderPlaying: Bool { _isPrerenderPlaying }

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)

        // 监听 readyToPlay 事件，更新状态
        context.add(self, event: .playerReadyToPlaySticky, option: .execOnlyOnce) { [weak self] _, _ in
            guard let self = self else { return }
            guard self._state == .preparing || self._state == .readyToDisplay else { return }
            self._state = .readyToPlay
        }
    }

    public func prerenderIfNeed() {
        guard _state == .idle else { return }
        guard let engine = engineService else { return }
        guard engine.currentURL != nil else { return }
        guard let player = engine.avPlayer else { return }

        _state = .preparing

        // preroll 需要 status == .readyToPlay
        if player.status == .readyToPlay {
            startPreroll(player: player)
        } else {
            // 等待 readyToPlay 后再 preroll
            context?.add(self, event: .playerReadyToPlaySticky, option: .execOnlyOnce) { [weak self] _, _ in
                guard let self = self, let player = self.engineService?.avPlayer else { return }
                self.startPreroll(player: player)
            }
        }
    }

    private func startPreroll(player: AVPlayer) {
        // 可能是 .preparing 或 .readyToPlay（readyToPlay 事件先触发的情况）
        guard _state == .preparing || _state == .readyToPlay else { return }

        player.preroll(atRate: 1.0) { [weak self] finished in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                // 状态可能已经被改变（如 resetPlayer），检查是否仍在预渲染流程中
                guard self._state == .preparing || self._state == .readyToPlay else { return }

                if finished {
                    // preroll 成功，管线已预热，首帧已渲染
                    self._state = .readyToDisplay
                    if let container = self.playerContainerView {
                        container.isHidden = false
                    }
                } else {
                    // preroll 被中断（seek/replaceItem/cancel）
                    self._state = .cancelled
                }
            }
        }
    }

    public func dragPlay() {
        guard let engine = engineService else { return }
        _isPrerenderPlaying = true
        engine.volume = 1.0
        engine.play()
    }

    public func releasePlayer() {
        releasePlayerContainerView()
        engineService?.pause()
        engineService?.replaceCurrentItem(with: nil)
    }

    public func resetPlayer() {
        engineService?.pause()
        engineService?.replaceCurrentItem(with: nil)
        _state = .idle
        _isPrerenderPlaying = false
    }

    public func attachOnSuperView(_ superView: UIView) {
        guard let pv = engineService?.playerView else { return }
        if playerContainerView?.superview === superView { return }

        if playerContainerView == nil {
            let container = UIView()
            container.clipsToBounds = true
            container.backgroundColor = .black
            playerContainerView = container
        }

        guard let container = playerContainerView else { return }
        container.subviews.forEach { $0.removeFromSuperview() }
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = _state != .readyToDisplay && _state != .readyToPlay

        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        container.addSubview(pv)
        superView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: superView.topAnchor),
            container.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
            pv.topAnchor.constraint(equalTo: container.topAnchor),
            pv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    public func removeFromSuperView(_ superView: UIView) {
        if playerContainerView?.superview === superView {
            playerContainerView?.removeFromSuperview()
            engineService?.playerView?.removeFromSuperview()
            engineService?.pause()
        }
    }

    public func detachEngine() -> BasePlugin? {
        releasePlayerContainerView()
        return (context as? Context)?.detachInstance(for: PlayerEngineCoreService.self)
    }

    private func releasePlayerContainerView() {
        playerContainerView?.isHidden = true
        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
        playerContainerView?.removeFromSuperview()
        playerContainerView = nil
    }
}
