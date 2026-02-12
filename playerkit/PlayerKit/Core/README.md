# PlayerKit Core 架构说明

## 概述

PlayerKit Core 使用 Swift + CCL 框架实现完整的播放器能力体系。

## 目录结构

```
Core/
├── PlayerCoreService.swift          # 核心服务聚合入口
├── Engine/                           # 播放引擎
├── ControlView/                      # 播控UI管理
├── Tracker/                          # 数据埋点
├── Data/                             # 数据管理
├── Process/                          # 播放进度
├── PlaybackControl/                  # 播放控制
├── MediaControl/                     # 媒体控制（音量/亮度）
├── FullScreen/                       # 全屏管理
├── Speed/                            # 倍速播放
├── Resolution/                       # 分辨率/清晰度
├── Time/                             # 时间控制
├── Panel/                            # 面板管理
├── Toast/                            # Toast提示
├── Looping/                          # 循环播放
├── Replay/                           # 重播
├── PreNext/                          # 预加载下一个
├── TipManager/                       # 提示管理
├── FinishView/                       # 结束视图
├── CoverMask/                        # 遮罩视图
├── PreRender/                        # 预渲染
├── AppActive/                        # 前后台处理
├── Context/                          # Context管理
├── QosTracker/                       # QoS质量监控
└── Debug/                            # 调试服务
```

## 模块列表

| 模块 | 服务协议 | 组件实现 | 说明 |
|------|---------|---------|------|
| Engine | `PlayerEngineCoreService` | `PlayerEngineCoreComp` | 基于 AVPlayer 的播放引擎 |
| PlaybackControl | `PlayerPlaybackControlService` | `PlayerPlaybackControlComp` | 播放/暂停/停止控制 |
| Process | `PlayerProcessService` | `PlayerProcessComp` | 进度管理、拖动、Seek |
| Tracker | `PlayerTrackerService` | `PlayerTrackerComp` | 埋点节点系统 |
| ControlView | `PlayerControlViewService` | `PlayerControlViewComp` | 播控UI管理 |
| MediaControl | `PlayerMediaControlService` | `PlayerMediaControlComp` | 音量/亮度控制 |
| FullScreen | `PlayerFullScreenService` | `PlayerFullScreenComp` | 全屏切换 |
| Speed | `PlayerSpeedService` | `PlayerSpeedComp` | 倍速播放 |
| Resolution | `PlayerResolutionService` | `PlayerResolutionComp` | 清晰度切换 |
| TimeControl | `PlayerTimeControlService` | `PlayerTimeControlComp` | 时间格式化 |
| Looping | `PlayerLoopingService` | `PlayerLoopingComp` | 循环模式 |
| Replay | `PlayerReplayService` | `PlayerReplayComp` | 重播功能 |
| PreNext | `PlayerPreNextService` | `PlayerPreNextComp` | 预加载下一个 |
| Panel | `PlayerPanelService` | `PlayerPanelComp` | 面板管理 |
| Toast | `PlayerToastService` | `PlayerToastComp` | Toast提示 |
| FinishView | `PlayerFinishViewService` | `PlayerFinishViewComp` | 结束视图 |
| CoverMask | `PlayerCoverMaskService` | `PlayerCoverMaskComp` | 遮罩视图 |
| PreRender | `PlayerPreRenderService` | `PlayerPreRenderComp` | 预渲染 |
| AppActive | `PlayerAppActiveService` | `PlayerAppActiveComp` | 前后台处理 |
| Context | `PlayerContextService` | `PlayerContextComp` | Context管理 |
| QosTracker | `PlayerQosService` | `PlayerQosComp` | QoS监控 |
| Debug | `PlayerDebugService` | `PlayerDebugComp` | 调试服务 |
| TipManager | `PlayerTipManagerService` | `PlayerTipManagerComp` | 提示管理 |

## 使用方式

### 1. 注册组件

```swift
let player = Player()

// 注册核心组件
player.context.registerCls(
    PlayerEngineCoreComp.self,
    protocol: PlayerEngineCoreService.self,
    options: .whenRegistered
)

player.context.registerCls(
    PlayerPlaybackControlComp.self,
    protocol: PlayerPlaybackControlService.self,
    options: .whenRegistered
)

// ... 注册其他组件
```

### 2. 获取服务

```swift
let engineService = player.context.resolveService(PlayerEngineCoreService.self)
let controlService = player.context.resolveService(PlayerPlaybackControlService.self)
```

### 3. 使用 @CCLService 依赖注入

```swift
class MyComponent: CCLBaseComp {
    @CCLService var engineService: PlayerEngineCoreService?
    @CCLService var controlService: PlayerPlaybackControlService?

    override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
        setupPropertyWrappers()

        // 使用服务
        engineService?.play()
    }
}
```

### 4. 监听事件

```swift
context.add(self, event: .playerPlaybackStateChanged) { state, _ in
    print("播放状态: \(state)")
}

context.add(self, event: .playerSpeedDidChange) { speed, _ in
    print("倍速: \(speed)")
}
```

## 事件列表

所有事件定义在 `PlayerCoreService.swift` 中：

### Engine 事件
- `playerEngineDidCreateSticky` - 引擎已创建（粘性）
- `playerEngineDidChange` - 引擎已改变
- `playerPlaybackStateChanged` - 播放状态变化
- `playerReadyForDisplaySticky` - 准备显示（粘性）
- `playerReadyToPlaySticky` - 准备播放（粘性）
- `playerPlaybackDidFinish` - 播放完成
- `playerPlaybackDidFail` - 播放失败

### Progress/Seek 事件
- `playerProgressBeginScrubbing` - 开始拖动
- `playerProgressScrubbing` - 拖动中
- `playerProgressEndScrubbing` - 结束拖动
- `playerSliderSeekBegin/End` - Slider Seek
- `playerGestureSeekBegin/End` - 手势 Seek

### ControlView 事件
- `playerControlViewTemplateChanged` - 模板更新
- `playerControlViewDidLoadSticky` - 播控加载完成（粘性）
- `playerShowControl` - 显示状态变化
- `playerControlViewDidChangeLock` - 锁屏状态变化
- `playerControlViewSingleTap` - 单击播控

### FullScreen 事件
- `playerFullScreenStateChanged` - 全屏状态变化
- `playerWillEnterFullScreen` - 将进入全屏
- `playerDidEnterFullScreen` - 已进入全屏
- `playerWillExitFullScreen` - 将退出全屏
- `playerDidExitFullScreen` - 已退出全屏

### 其他事件
- `playerSpeedDidChange` - 倍速变化
- `playerResolutionDidChange` - 分辨率变化
- `playerVolumeDidChange` - 音量变化
- `playerBrightnessDidChange` - 亮度变化
- `playerLoopingDidChange` - 循环状态变化
- `playerTimeDidChange` - 时间更新
- `playerDurationDidSet` - 总时长设置
- `playerPreNextDidStart/Finish` - 预加载状态
- `playerAppDidBecomeActive/ResignActive` - 前后台状态

## 下一步

1. 将 Core 目录添加到 Xcode 项目
2. 根据实际业务需求完善各组件实现
3. 添加 UI 相关的视图组件
4. 完善埋点上报逻辑
5. 添加单元测试
