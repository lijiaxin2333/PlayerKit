//
//  PlayerCoverMaskPlugin.swift
//  playerkit
//
//  遮罩视图组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 遮罩视图，用于在播放器上显示半透明遮罩
 */
private class CoverMaskView: UIView {

    /**
     * 使用指定颜色初始化遮罩
     */
    init(color: UIColor = .black.withAlphaComponent(0.5)) {
        super.init(frame: .zero)
        backgroundColor = color
    }

    /**
     * 使用 coder 初始化
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

/**
 * 遮罩视图插件，管理播放器上的遮罩显示与隐藏
 */
@MainActor
public final class PlayerCoverMaskPlugin: BasePlugin, PlayerCoverMaskService {

    /**
     * 配置模型类型
     */
    public typealias ConfigModelType = PlayerCoverMaskConfigModel

    // MARK: - Properties

    /**
     * 播放引擎核心服务
     */
    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    /**
     * 遮罩视图字典，key 为唯一标识
     */
    private var coverMasks: [String: CoverMaskView] = [:]

    // MARK: - Initialization

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    /**
     * 配置更新
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerCoverMaskService

    /**
     * 显示遮罩
     */
    public func showCoverMask(_ mask: AnyObject) {
        guard let playerView = engineService?.playerView,
              let maskView = mask as? UIView else {
            print("[PlayerCoverMaskPlugin] 无法显示遮罩: 播放器视图不可用或 mask 不是 UIView")
            return
        }

        let containerView: UIView
        if maskView is CoverMaskView {
            containerView = maskView
        } else {
            containerView = UIView(frame: playerView.bounds)
            containerView.backgroundColor = .clear
            maskView.frame = containerView.bounds
            containerView.addSubview(maskView)
        }

        containerView.translatesAutoresizingMaskIntoConstraints = false
        playerView.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: playerView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
        ])

        if let config = configModel as? PlayerCoverMaskConfigModel, !config.allowTouchThrough {
            containerView.isUserInteractionEnabled = true
        }

        let key = UUID().uuidString
        coverMasks[key] = containerView as? CoverMaskView ?? {
            let wrapper = CoverMaskView(color: .clear)
            wrapper.addSubview(containerView)
            return wrapper
        }()

        print("[PlayerCoverMaskPlugin] 显示遮罩: \(mask)")
    }

    /**
     * 隐藏遮罩
     */
    public func hideCoverMask(_ mask: AnyObject) {
        guard let maskView = mask as? UIView else { return }

        let toRemove = coverMasks.filter { key, view in
            view == maskView || view.subviews.contains(maskView)
        }

        for (key, view) in toRemove {
            view.removeFromSuperview()
            coverMasks.removeValue(forKey: key)
        }

        print("[PlayerCoverMaskPlugin] 隐藏遮罩")
    }

    /**
     * 隐藏所有遮罩
     */
    public func hideAllCoverMasks() {
        let count = coverMasks.count
        coverMasks.values.forEach { $0.removeFromSuperview() }
        coverMasks.removeAll()
        print("[PlayerCoverMaskPlugin] 隐藏所有遮罩，数量: \(count)")
    }
}
