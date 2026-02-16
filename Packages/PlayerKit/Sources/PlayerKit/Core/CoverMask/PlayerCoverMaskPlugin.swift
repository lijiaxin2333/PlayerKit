//
//  PlayerCoverMaskPlugin.swift
//  playerkit
//
//  遮罩视图组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 遮罩视图

private class CoverMaskView: UIView {
    init(color: UIColor = .black.withAlphaComponent(0.5)) {
        super.init(frame: .zero)
        backgroundColor = color
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - 遮罩视图组件

@MainActor
public final class PlayerCoverMaskPlugin: BasePlugin, PlayerCoverMaskService {

    public typealias ConfigModelType = PlayerCoverMaskConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var coverMasks: [String: CoverMaskView] = [:]

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
    }

    // MARK: - PlayerCoverMaskService

    public func showCoverMask(_ mask: AnyObject) {
        guard let playerView = engineService?.playerView,
              let maskView = mask as? UIView else {
            print("[PlayerCoverMaskPlugin] 无法显示遮罩: 播放器视图不可用或 mask 不是 UIView")
            return
        }

        // 如果 mask 不是 CoverMaskView 类型，包装它
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

        // 设置交互
        if let config = configModel as? PlayerCoverMaskConfigModel, !config.allowTouchThrough {
            containerView.isUserInteractionEnabled = true
        }

        let key = UUID().uuidString
        coverMasks[key] = containerView as? CoverMaskView ?? {
            // 为自定义视图创建一个包装
            let wrapper = CoverMaskView(color: .clear)
            wrapper.addSubview(containerView)
            return wrapper
        }()

        print("[PlayerCoverMaskPlugin] 显示遮罩: \(mask)")
    }

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

    public func hideAllCoverMasks() {
        let count = coverMasks.count
        coverMasks.values.forEach { $0.removeFromSuperview() }
        coverMasks.removeAll()
        print("[PlayerCoverMaskPlugin] 隐藏所有遮罩，数量: \(count)")
    }
}
