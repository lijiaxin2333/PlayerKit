# Gesture 模块

播放器手势识别组件，完全 CCL 驱动，注册后自动具备手势能力。

## 自动绑定

GestureComp 在 componentDidLoad 时监听 .playerEngineDidCreateSticky 粘性事件，
自动将 engine 的 playerView 设为 gestureView 并安装所有手势识别器。

VC/Cell 无需手动设置 gestureView。

## 外部覆盖

内流等场景可手动设 gestureView = vc.view 来扩大手势响应区域。
设 gestureView = nil 时自动回退到 playerView（rebindPlayerView）。

## 手势类型

singleTap / doubleTap / pan / pinch / longPress

每种手势可通过 is{Type}Enabled 开关独立控制，
也可通过 disableGesture(_:forScene:) 按场景禁用。

## CCL 事件

- playerGestureSingleTap
- playerGestureDoubleTap
- playerGesturePan
- playerGesturePinch
- playerGestureLongPress（携带 UIGestureRecognizer.State.rawValue）
