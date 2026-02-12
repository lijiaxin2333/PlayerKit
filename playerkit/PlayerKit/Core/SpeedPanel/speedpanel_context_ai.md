# SpeedPanel 模块

倍速选择面板组件，完全由 CCL 事件驱动，不需要外部手动调用。

## 架构

- **PlayerSpeedPanelService** - 协议，暴露 isShowing / dismissPanel
- **PlayerSpeedPanelComp** - CCL 组件实现
  - 通过 @CCLService 依赖 PlayerSpeedService、PlayerGestureService
  - 监听 `.playerGestureLongPress` 事件（began），自动弹出面板
  - 监听 `.playerSpeedDidChange` 事件，同步面板选中状态
  - 面板展示在 gestureView 所在 window 的 rootViewController.view 上
- **PlayerSpeedPanelView** - 纯 UI 视图，底部弹出面板

## 触发链路

GestureComp(playerView 上的长按) → post .playerGestureLongPress → SpeedPanelComp 收到 → showPanel

## 手势自动绑定

GestureComp 在 componentDidLoad 时监听 .playerEngineDidCreateSticky 事件，自动将 playerView 设为 gestureView。
VC/Cell 无需手动设置 gestureView，Player 注册后即具备手势能力。

内流等场景可覆盖 gestureView 指向更大的 view（如 VC.view），dismiss 时设 gestureView = nil 会自动回退到 playerView。

## 事件

- playerSpeedPanelDidShow
- playerSpeedPanelDidDismiss
