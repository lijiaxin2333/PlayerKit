import Foundation
import UIKit

/**
 * 可参与场景切换的协议（通用）
 */
@MainActor
public protocol PlayerTransitionable: AnyObject {

    /** 用于迁移的播放器实例 */
    var transitionPlayer: Player? { get }

    /** 播放器容器视图 */
    var playerContainerView: UIView? { get }

    /**
     * 附加播放器
     */
    func attachPlayer(_ player: Player)

    /**
     * 分离播放器
     */
    func detachPlayer()

    /**
     * 附加失败时的回调
     */
    func handleAttachFailed()
}

/**
 * PlayerTransitionable 扩展，提供默认实现
 */
public extension PlayerTransitionable {

    /**
     * 执行播放器视图的附加（将视图添加到容器）
     */
    func performAttachPlayerView(_ player: Player) {
        guard let container = playerContainerView,
              let pv = player.engineService?.playerView else { return }
        pv.translatesAutoresizingMaskIntoConstraints = false
        pv.isHidden = false
        container.addSubview(pv)
        NSLayoutConstraint.activate([
            pv.topAnchor.constraint(equalTo: container.topAnchor),
            pv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            pv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            pv.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    /**
     * 执行播放器视图的分离（移除子视图）
     */
    func performDetachPlayerView() {
        playerContainerView?.subviews.forEach { $0.removeFromSuperview() }
    }

    /**
     * 默认附加实现：添加播放器视图到容器
     */
    func attachPlayer(_ player: Player) {
        performAttachPlayerView(player)
    }

    /**
     * 默认分离实现：清空容器子视图
     */
    func detachPlayer() {
        performDetachPlayerView()
    }

    /**
     * 默认附加失败处理：空实现
     */
    func handleAttachFailed() {}
}

/**
 * 迁移源协议，表示可分离播放器的来源
 */
@MainActor
public protocol PlayerTransitionSource: PlayerTransitionable {

    /**
     * 是否可以分离播放器
     */
    func canDetachPlayer() -> Bool
}

/**
 * PlayerTransitionSource 扩展，默认允许分离
 */
public extension PlayerTransitionSource {

    /**
     * 默认实现：允许分离
     */
    func canDetachPlayer() -> Bool { true }
}

/**
 * 迁移目标协议，表示可接收播放器的目标
 */
@MainActor
public protocol PlayerTransitionDestination: PlayerTransitionable {

    /**
     * 是否可以附加指定播放器
     */
    func canAttachPlayer(_ player: Player) -> Bool
}

/**
 * PlayerTransitionDestination 扩展，默认允许附加
 */
public extension PlayerTransitionDestination {

    /**
     * 默认实现：允许附加
     */
    func canAttachPlayer(_ player: Player) -> Bool { true }
}
