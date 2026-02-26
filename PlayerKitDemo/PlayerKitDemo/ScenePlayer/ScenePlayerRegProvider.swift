import Foundation
import PlayerKit

/// 场景层插件注册器
/// 注册所有场景层 UI 相关的插件
@MainActor
public final class ScenePlayerRegProvider: RegisterProvider {

    /// 是否包含调试插件
    public var includeDebugPlugins: Bool = false

    public init(includeDebugPlugins: Bool = false) {
        self.includeDebugPlugins = includeDebugPlugins
    }

    public func registerPlugins(with registerSet: PluginRegisterSet) {
        // 播控视图
        registerSet.addEntry(pluginClass: PlayerControlViewPlugin.self,
                            serviceType: PlayerControlViewService.self)

        // 播放完成视图
        registerSet.addEntry(pluginClass: PlayerFinishViewPlugin.self,
                            serviceType: PlayerFinishViewService.self)

        // 面板
        registerSet.addEntry(pluginClass: PlayerPanelPlugin.self,
                            serviceType: PlayerPanelService.self)

        // 速度面板
        registerSet.addEntry(pluginClass: PlayerSpeedPanelPlugin.self,
                            serviceType: PlayerSpeedPanelService.self)

        // Toast
        registerSet.addEntry(pluginClass: PlayerToastPlugin.self,
                            serviceType: PlayerToastService.self)

        // 全屏
        registerSet.addEntry(pluginClass: PlayerFullScreenPlugin.self,
                            serviceType: PlayerFullScreenService.self)

        // 手势
        registerSet.addEntry(pluginClass: PlayerGesturePlugin.self,
                            serviceType: PlayerGestureService.self)

        // 缩放
        registerSet.addEntry(pluginClass: PlayerZoomPlugin.self,
                            serviceType: PlayerZoomService.self)


        // 提示管理
        registerSet.addEntry(pluginClass: PlayerTipManagerPlugin.self,
                            serviceType: PlayerTipManagerService.self)

        // 调试插件（可选）
        if includeDebugPlugins {
            registerSet.addEntry(pluginClass: PlayerDebugPlugin.self,
                                serviceType: PlayerDebugService.self)
        }
    }
}
