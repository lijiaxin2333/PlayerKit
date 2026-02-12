# ShowcaseDetailControlComp

CCL 组件，注册为 `ShowcaseDetailControlService`，挂载在 `feedPlayer.context` 上。

## 职责

- 配置手势 Service（gestureView、pan/pinch 开关）
- 配置 StartTime、QoS、Tracker、PreNext Service
- 监听播放状态/进度/卡顿/播放完成事件，通过回调通知 VC 更新 UI
- 封装所有控制按钮的业务逻辑（play/pause、speed、mute、loop、subtitle、snapshot、fullscreen、debug）
- 封装 slider scrubbing 逻辑
- 封装手势响应逻辑（pan -> scrub/brightness/volume，longPress -> 倍速，pinch -> scalingMode）
- 管理控制面板自动隐藏定时器

## 依赖

- `PlayerPlaybackControlService`
- `PlayerSpeedService`
- `PlayerMediaControlService`
- `PlayerProcessService`
- `PlayerEngineCoreService`
- `PlayerSubtitleService`
- `PlayerSnapshotService`
- `PlayerFullScreenService`
- `PlayerDebugService`
- `PlayerQosService`
- `PlayerTrackerService`
- `PlayerPreNextService`
- `PlayerStartTimeService`
- `PlayerTipManagerService`
- `PlayerFinishViewService`
- `PlayerToastService`

## 回调

- `onPlaybackStateChanged` — 播放/暂停状态变化
- `onProgressUpdate` — 进度更新（progress, currentTime, duration）
- `onControlShouldShow` — 控制面板应显示/隐藏
