//
//  PlayerPanelPlugin.swift
//  playerkit
//
//  面板管理组件实现
//

import Foundation
import AVFoundation
import UIKit

// MARK: - 面板容器视图

private class PanelContainerView: UIView {
    internal let contentView = UIView()
    private var backgroundTapAction: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black.withAlphaComponent(0.5)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8),
            contentView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.8),
        ])
    }

    func setContent(_ panelView: UIView) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        panelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(panelView)

        NSLayoutConstraint.activate([
            panelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            panelView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            panelView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            panelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    func setBackgroundTapAction(_ action: @escaping () -> Void) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        addGestureRecognizer(tapGesture)
        backgroundTapAction = action
    }

    @objc private func handleBackgroundTap() {
        backgroundTapAction?()
    }
}

// MARK: - 面板管理组件

@MainActor
public final class PlayerPanelPlugin: BasePlugin, PlayerPanelService {

    public typealias ConfigModelType = PlayerPanelConfigModel

    // MARK: - Properties

    @PlayerPlugin(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var visiblePanels: [String: PanelContainerView] = [:]

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

    // MARK: - PlayerPanelService

    public func showPanel(_ panel: AnyObject, at position: PlayerPanelPosition, animated: Bool) {
        guard let playerView = engineService?.playerView,
              let panelView = panel as? UIView else {
            print("[PlayerPanelPlugin] 无法显示面板: 播放器视图不可用或面板不是 UIView")
            return
        }

        // 创建容器
        let container = PanelContainerView(frame: playerView.bounds)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.alpha = 0

        // 设置面板内容
        container.setContent(panelView)

        // 设置背景点击关闭
        if let config = configModel as? PlayerPanelConfigModel, config.tapBackgroundToHide {
            container.setBackgroundTapAction { [weak self] in
                self?.hidePanel(panel, animated: true)
            }
        }

        playerView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: playerView.topAnchor),
            container.leadingAnchor.constraint(equalTo: playerView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: playerView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: playerView.bottomAnchor),
        ])

        let key = UUID().uuidString
        visiblePanels[key] = container

        // 动画显示
        if animated {
            UIView.animate(withDuration: 0.25) {
                container.alpha = 1
            }
        } else {
            container.alpha = 1
        }

        print("[PlayerPanelPlugin] 显示面板: \(panel) at \(position)")
    }

    public func hidePanel(_ panel: AnyObject, animated: Bool) {
        guard let panelView = panel as? UIView else { return }

        let toRemove = visiblePanels.filter { $0.value.contentView.subviews.contains(panelView) }

        for (key, container) in toRemove {
            if animated {
                UIView.animate(withDuration: 0.25, animations: {
                    container.alpha = 0
                }) { _ in
                    container.removeFromSuperview()
                    self.visiblePanels.removeValue(forKey: key)
                }
            } else {
                container.removeFromSuperview()
                visiblePanels.removeValue(forKey: key)
            }
        }

        print("[PlayerPanelPlugin] 隐藏面板")
    }

    public func hideAllPanels(animated: Bool) {
        let panels = visiblePanels.values

        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                panels.forEach { $0.alpha = 0 }
            }) { _ in
                panels.forEach { $0.removeFromSuperview() }
            }
        } else {
            panels.forEach { $0.removeFromSuperview() }
        }

        visiblePanels.removeAll()
        print("[PlayerPanelPlugin] 隐藏所有面板，数量: \(panels.count)")
    }
}
