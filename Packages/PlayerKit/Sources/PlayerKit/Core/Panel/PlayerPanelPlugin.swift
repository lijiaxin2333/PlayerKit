import Foundation
import AVFoundation
import UIKit

/**
 * 面板容器视图，用于承载面板内容并处理背景点击
 */
private class PanelContainerView: UIView {
    /** 内容视图 */
    internal let contentView = UIView()
    /** 背景点击回调 */
    private var backgroundTapAction: (() -> Void)?

    /**
     * 指定 frame 初始化
     */
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    /**
     * 从 coder 初始化
     */
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    /**
     * 设置 UI 布局
     */
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

    /**
     * 设置面板内容视图
     */
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

    /**
     * 设置背景点击动作
     */
    func setBackgroundTapAction(_ action: @escaping () -> Void) {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap))
        addGestureRecognizer(tapGesture)
        backgroundTapAction = action
    }

    /**
     * 处理背景点击
     */
    @objc private func handleBackgroundTap() {
        backgroundTapAction?()
    }
}

/**
 * 面板管理插件，负责显示、隐藏播放器上的浮层面板
 * - 通过 PlayerViewService 获取视图容器，解耦对引擎层的直接依赖
 */
@MainActor
public final class PlayerPanelPlugin: BasePlugin, PlayerPanelService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerPanelConfigModel

    /** 视图服务依赖 */
    @PlayerPlugin private var viewService: PlayerViewService?

    /** 当前可见的面板容器映射 */
    private var visiblePanels: [String: PanelContainerView] = [:]

    /**
     * 初始化
     */
    public required override init() {
        super.init()
    }

    /**
     * 插件加载完成
     */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    /**
     * 配置插件
     */
    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    /**
     * 在指定位置显示面板
     */
    public func showPanel(_ panel: AnyObject, at position: PlayerPanelPosition, animated: Bool) {
        guard let actionView = viewService?.actionView,
              let panelView = panel as? UIView else {
            print("[PlayerPanelPlugin] 无法显示面板: actionView 不可用或面板不是 UIView")
            return
        }

        let container = PanelContainerView(frame: actionView.bounds)
        container.translatesAutoresizingMaskIntoConstraints = false
        container.alpha = 0
        container.playerViewType = .panelView

        container.setContent(panelView)

        if let config = configModel as? PlayerPanelConfigModel, config.tapBackgroundToHide {
            container.setBackgroundTapAction { [weak self] in
                self?.hidePanel(panel, animated: true)
            }
        }

        // 使用 PlayerActionView 的层级管理
        actionView.addSubview(container, viewType: .panelView)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: actionView.topAnchor),
            container.leadingAnchor.constraint(equalTo: actionView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: actionView.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: actionView.bottomAnchor),
        ])

        let key = UUID().uuidString
        visiblePanels[key] = container

        if animated {
            UIView.animate(withDuration: 0.25) {
                container.alpha = 1
            }
        } else {
            container.alpha = 1
        }

        print("[PlayerPanelPlugin] 显示面板: \(panel) at \(position)")
    }

    /**
     * 隐藏指定面板
     */
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

    /**
     * 隐藏所有面板
     */
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
