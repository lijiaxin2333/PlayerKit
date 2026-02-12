//
//  PlayerCoreService.swift
//  playerkit
//
//  PlayerKit Core 服务聚合
//

import Foundation
import AVFoundation
import UIKit

// MARK: - Core 服务导入

// 各个服务协议会通过 CCL 组件系统自动注册
// 使用时通过 context.resolveService(SERVICE_PROTOCOL.self) 获取

// MARK: - Core 事件定义汇总

public extension CCLEvent {
    // ===== Engine 事件 =====
    /// 播放器引擎已创建（粘性事件）
    static let playerEngineDidCreateSticky: CCLEvent = "PlayerEngineDidCreateSticky"
    /// 播放器引擎已改变
    static let playerEngineDidChange: CCLEvent = "PlayerEngineDidChange"
    /// 播放状态改变
    static let playerPlaybackStateChanged: CCLEvent = "PlayerPlaybackStateChanged"
    /// 准备好显示（粘性事件）
    static let playerReadyForDisplaySticky: CCLEvent = "PlayerReadyForDisplaySticky"
    /// 准备播放（粘性事件）
    static let playerReadyToPlay: CCLEvent = "PlayerReadyToPlay"
    static let playerReadyToPlaySticky: CCLEvent = "PlayerReadyToPlaySticky"
    /// 加载状态改变
    static let playerLoadStateDidChange: CCLEvent = "PlayerLoadStateDidChange"
    /// 播放完成
    static let playerPlaybackDidFinish: CCLEvent = "PlayerPlaybackDidFinish"
    /// 播放失败
    static let playerPlaybackDidFail: CCLEvent = "PlayerPlaybackDidFail"

    // ===== Progress/Seek 事件 =====
    /// 进度开始拖动
    static let playerProgressBeginScrubbing: CCLEvent = "PlayerProgressBeginScrubbing"
    /// 进度拖动中
    static let playerProgressScrubbing: CCLEvent = "PlayerProgressScrubbing"
    /// 进度结束拖动
    static let playerProgressEndScrubbing: CCLEvent = "PlayerProgressEndScrubbing"
    /// Slider 触发的 Seek 开始
    static let playerSliderSeekBegin: CCLEvent = "PlayerSliderSeekBegin"
    /// Slider 触发的 Seek 结束
    static let playerSliderSeekEnd: CCLEvent = "PlayerSliderSeekEnd"
    /// 手势触发的 Seek 开始
    static let playerGestureSeekBegin: CCLEvent = "PlayerGestureSeekBegin"
    /// 手势触发的 Seek 结束
    static let playerGestureSeekEnd: CCLEvent = "PlayerGestureSeekEnd"
    /// Seek 开始
    static let playerSeekBegin: CCLEvent = "PlayerSeekBegin"
    /// Seek 结束
    static let playerSeekEnd: CCLEvent = "PlayerSeekEnd"
    /// 开始卡顿
    static let playerPlayingStalledBegin: CCLEvent = "PlayerPlayingStalledBegin"
    /// 结束卡顿
    static let playerPlayingStalledEnd: CCLEvent = "PlayerPlayingStalledEnd"

    // ===== ControlView 事件 =====
    /// 播控模板更新
    static let playerControlViewTemplateChanged: CCLEvent = "PlayerControlViewTemplateChanged"
    /// 主动更新模板
    static let playerControlViewTryUpdateTemplate: CCLEvent = "PlayerControlViewTryUpdateTemplate"
    /// 播控初次加载完成（粘性事件）
    static let playerControlViewDidLoadSticky: CCLEvent = "PlayerControlViewDidLoadSticky"
    /// 播控显示状态更新
    static let playerShowControl: CCLEvent = "PlayerShowControl"
    /// 播控锁屏状态更新
    static let playerControlViewDidChangeLock: CCLEvent = "PlayerControlViewDidChangeLock"
    /// 单击播控
    static let playerControlViewSingleTap: CCLEvent = "PlayerControlViewSingleTap"
    /// 播控 Focus 状态更新
    static let playerControlViewDidChangeFocus: CCLEvent = "PlayerControlViewDidChangeFocus"

    // ===== FullScreen 事件 =====
    /// 全屏状态改变
    static let playerFullScreenStateChanged: CCLEvent = "PlayerFullScreenStateChanged"
    /// 将要进入全屏
    static let playerWillEnterFullScreen: CCLEvent = "PlayerWillEnterFullScreen"
    /// 已经进入全屏
    static let playerDidEnterFullScreen: CCLEvent = "PlayerDidEnterFullScreen"
    /// 将要退出全屏
    static let playerWillExitFullScreen: CCLEvent = "PlayerWillExitFullScreen"
    /// 已经退出全屏
    static let playerDidExitFullScreen: CCLEvent = "PlayerDidExitFullScreen"

    // ===== Speed 事件 =====
    /// 倍速改变
    static let playerSpeedDidChange: CCLEvent = "PlayerSpeedDidChange"

    // ===== Resolution 事件 =====
    /// 分辨率改变
    static let playerResolutionDidChange: CCLEvent = "PlayerResolutionDidChange"
    /// 获取到分辨率列表
    static let playerDidFetchResolutions: CCLEvent = "PlayerDidFetchResolutions"

    // ===== MediaControl 事件 =====
    /// 音量改变
    static let playerVolumeDidChange: CCLEvent = "PlayerVolumeDidChange"
    /// 亮度改变
    static let playerBrightnessDidChange: CCLEvent = "PlayerBrightnessDidChange"

    // ===== Looping 事件 =====
    /// 循环状态改变
    static let playerLoopingDidChange: CCLEvent = "PlayerLoopingDidChange"

    // ===== Time 事件 =====
    /// 时间更新
    static let playerTimeDidChange: CCLEvent = "PlayerTimeDidChange"
    /// 总时长已设置
    static let playerDurationDidSet: CCLEvent = "PlayerDurationDidSet"

    // ===== PreNext 事件 =====
    /// 预加载下一个开始
    static let playerPreNextDidStart: CCLEvent = "PlayerPreNextDidStart"
    /// 预加载下一个完成
    static let playerPreNextDidFinish: CCLEvent = "PlayerPreNextDidFinish"

    // ===== AppActive 事件 =====
    static let playerAppDidBecomeActive: CCLEvent = "PlayerAppDidBecomeActive"
    static let playerAppDidResignActive: CCLEvent = "PlayerAppDidResignActive"

    // ===== Pool 事件 =====
    static let playerEngineDidEnqueueToPool: CCLEvent = "PlayerEngineDidEnqueueToPool"
    static let playerEngineDidDequeueFromPool: CCLEvent = "PlayerEngineDidDequeueFromPool"
    static let playerEnginePoolDidClear: CCLEvent = "PlayerEnginePoolDidClear"

    // ===== Scene 事件 =====
    static let playerSceneDidRegister: CCLEvent = "PlayerSceneDidRegister"
    static let playerSceneDidUnregister: CCLEvent = "PlayerSceneDidUnregister"
    static let playerSceneDidChange: CCLEvent = "PlayerSceneDidChange"

    // ===== SceneContext - TypedPlayer 事件 =====
    // typedPlayerDidAddToSceneSticky / typedPlayerWillRemoveFromScene
    // 定义在 PlayerTypedPlayerLayeredService.swift

    // ===== SceneContext - Extension 事件 =====
    // extensionDidAddToContextSticky / extensionWillRemoveFromContext
    // 定义在 PlayerExtensionLayeredService.swift

    // ===== Transfer 事件 =====
    static let playerEngineWillTransfer: CCLEvent = "PlayerEngineWillTransfer"
    static let playerEngineDidTransfer: CCLEvent = "PlayerEngineDidTransfer"

    // ===== PreRender Manager 事件 =====
    static let playerPreRenderStarted: CCLEvent = "PlayerPreRenderStarted"
    static let playerPreRenderReady: CCLEvent = "PlayerPreRenderReady"
    static let playerPreRenderTimeout: CCLEvent = "PlayerPreRenderTimeout"

    // ===== Preload 事件 =====
    static let playerPreloadTaskDidFinish: CCLEvent = "PlayerPreloadTaskDidFinish"

    // ===== StartTime 事件 =====
    static let playerStartTimeDidResolve: CCLEvent = "PlayerStartTimeDidResolve"

    // ===== Gesture 事件 =====
    static let playerGestureSingleTap: CCLEvent = "PlayerGestureSingleTap"
    static let playerGestureDoubleTap: CCLEvent = "PlayerGestureDoubleTap"
    static let playerGesturePan: CCLEvent = "PlayerGesturePan"
    static let playerGesturePinch: CCLEvent = "PlayerGesturePinch"
    static let playerGestureLongPress: CCLEvent = "PlayerGestureLongPress"

    // ===== Subtitle 事件 =====
    static let playerSubtitleDidChange: CCLEvent = "PlayerSubtitleDidChange"
    static let playerSubtitleCueDidUpdate: CCLEvent = "PlayerSubtitleCueDidUpdate"

    // ===== Snapshot 事件 =====
    static let playerSnapshotDidCapture: CCLEvent = "PlayerSnapshotDidCapture"

    // ===== SpeedPanel 事件 =====
    static let playerSpeedPanelDidShow: CCLEvent = "PlayerSpeedPanelDidShow"
    static let playerSpeedPanelDidDismiss: CCLEvent = "PlayerSpeedPanelDidDismiss"

    // ===== Showcase 场景级事件 =====
    static let showcaseFeedPageWillChange: CCLEvent = "ShowcaseFeedPageWillChange"
    static let showcaseFeedPageDidChange: CCLEvent = "ShowcaseFeedPageDidChange"
    static let showcaseFeedDataDidLoad: CCLEvent = "ShowcaseFeedDataDidLoad"
    static let showcaseFeedDataDidLoadMore: CCLEvent = "ShowcaseFeedDataDidLoadMore"
    static let showcaseFeedCellWillDisplay: CCLEvent = "ShowcaseFeedCellWillDisplay"
}
