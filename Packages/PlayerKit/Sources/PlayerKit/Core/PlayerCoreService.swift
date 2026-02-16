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

// 各个服务协议会通过插件系统自动注册
// 使用时通过 context.resolveService(SERVICE_PROTOCOL.self) 获取

// MARK: - Core 事件定义汇总

public extension Event {
    // ===== Engine 事件 =====
    /// 播放器引擎已创建（粘性事件）
    static let playerEngineDidCreateSticky: Event = "PlayerEngineDidCreateSticky"
    /// 播放器引擎已改变
    static let playerEngineDidChange: Event = "PlayerEngineDidChange"
    /// 播放状态改变
    static let playerPlaybackStateChanged: Event = "PlayerPlaybackStateChanged"
    /// 准备好显示（粘性事件）
    static let playerReadyForDisplaySticky: Event = "PlayerReadyForDisplaySticky"
    /// 准备播放（粘性事件）
    static let playerReadyToPlay: Event = "PlayerReadyToPlay"
    static let playerReadyToPlaySticky: Event = "PlayerReadyToPlaySticky"
    /// 加载状态改变
    static let playerLoadStateDidChange: Event = "PlayerLoadStateDidChange"
    /// 播放完成
    static let playerPlaybackDidFinish: Event = "PlayerPlaybackDidFinish"
    /// 播放失败
    static let playerPlaybackDidFail: Event = "PlayerPlaybackDidFail"

    // ===== Progress/Seek 事件 =====
    /// 进度开始拖动
    static let playerProgressBeginScrubbing: Event = "PlayerProgressBeginScrubbing"
    /// 进度拖动中
    static let playerProgressScrubbing: Event = "PlayerProgressScrubbing"
    /// 进度结束拖动
    static let playerProgressEndScrubbing: Event = "PlayerProgressEndScrubbing"
    /// Slider 触发的 Seek 开始
    static let playerSliderSeekBegin: Event = "PlayerSliderSeekBegin"
    /// Slider 触发的 Seek 结束
    static let playerSliderSeekEnd: Event = "PlayerSliderSeekEnd"
    /// 手势触发的 Seek 开始
    static let playerGestureSeekBegin: Event = "PlayerGestureSeekBegin"
    /// 手势触发的 Seek 结束
    static let playerGestureSeekEnd: Event = "PlayerGestureSeekEnd"
    /// Seek 开始
    static let playerSeekBegin: Event = "PlayerSeekBegin"
    /// Seek 结束
    static let playerSeekEnd: Event = "PlayerSeekEnd"
    /// 开始卡顿
    static let playerPlayingStalledBegin: Event = "PlayerPlayingStalledBegin"
    /// 结束卡顿
    static let playerPlayingStalledEnd: Event = "PlayerPlayingStalledEnd"

    // ===== ControlView 事件 =====
    /// 播控模板更新
    static let playerControlViewTemplateChanged: Event = "PlayerControlViewTemplateChanged"
    /// 主动更新模板
    static let playerControlViewTryUpdateTemplate: Event = "PlayerControlViewTryUpdateTemplate"
    /// 播控初次加载完成（粘性事件）
    static let playerControlViewDidLoadSticky: Event = "PlayerControlViewDidLoadSticky"
    /// 播控显示状态更新
    static let playerShowControl: Event = "PlayerShowControl"
    /// 播控锁屏状态更新
    static let playerControlViewDidChangeLock: Event = "PlayerControlViewDidChangeLock"
    /// 单击播控
    static let playerControlViewSingleTap: Event = "PlayerControlViewSingleTap"
    /// 播控 Focus 状态更新
    static let playerControlViewDidChangeFocus: Event = "PlayerControlViewDidChangeFocus"

    // ===== FullScreen 事件 =====
    /// 全屏状态改变
    static let playerFullScreenStateChanged: Event = "PlayerFullScreenStateChanged"
    /// 将要进入全屏
    static let playerWillEnterFullScreen: Event = "PlayerWillEnterFullScreen"
    /// 已经进入全屏
    static let playerDidEnterFullScreen: Event = "PlayerDidEnterFullScreen"
    /// 将要退出全屏
    static let playerWillExitFullScreen: Event = "PlayerWillExitFullScreen"
    /// 已经退出全屏
    static let playerDidExitFullScreen: Event = "PlayerDidExitFullScreen"

    // ===== Speed 事件 =====
    /// 倍速改变
    static let playerSpeedDidChange: Event = "PlayerSpeedDidChange"

    // ===== Resolution 事件 =====
    /// 分辨率改变
    static let playerResolutionDidChange: Event = "PlayerResolutionDidChange"
    /// 获取到分辨率列表
    static let playerDidFetchResolutions: Event = "PlayerDidFetchResolutions"

    // ===== MediaControl 事件 =====
    /// 音量改变
    static let playerVolumeDidChange: Event = "PlayerVolumeDidChange"
    /// 亮度改变
    static let playerBrightnessDidChange: Event = "PlayerBrightnessDidChange"

    // ===== Looping 事件 =====
    /// 循环状态改变
    static let playerLoopingDidChange: Event = "PlayerLoopingDidChange"

    // ===== Time 事件 =====
    /// 时间更新
    static let playerTimeDidChange: Event = "PlayerTimeDidChange"
    /// 总时长已设置
    static let playerDurationDidSet: Event = "PlayerDurationDidSet"

    // ===== PreNext 事件 =====
    /// 预加载下一个开始
    static let playerPreNextDidStart: Event = "PlayerPreNextDidStart"
    /// 预加载下一个完成
    static let playerPreNextDidFinish: Event = "PlayerPreNextDidFinish"

    // ===== AppActive 事件 =====
    static let playerAppDidBecomeActive: Event = "PlayerAppDidBecomeActive"
    static let playerAppDidResignActive: Event = "PlayerAppDidResignActive"

    // ===== Pool 事件 =====
    static let playerEngineDidEnqueueToPool: Event = "PlayerEngineDidEnqueueToPool"
    static let playerEngineDidDequeueFromPool: Event = "PlayerEngineDidDequeueFromPool"
    static let playerEnginePoolDidClear: Event = "PlayerEnginePoolDidClear"

    // ===== Scene 事件 =====
    static let playerSceneDidRegister: Event = "PlayerSceneDidRegister"
    static let playerSceneDidUnregister: Event = "PlayerSceneDidUnregister"
    static let playerSceneDidChange: Event = "PlayerSceneDidChange"

    // ===== SceneContext - TypedPlayer 事件 =====
    // typedPlayerDidAddToSceneSticky / typedPlayerWillRemoveFromScene
    // 定义在 PlayerTypedPlayerLayeredService.swift

    // ===== SceneContext - Extension 事件 =====
    // extensionDidAddToContextSticky / extensionWillRemoveFromContext
    // 定义在 PlayerExtensionLayeredService.swift

    // ===== Transfer 事件 =====
    static let playerEngineWillTransfer: Event = "PlayerEngineWillTransfer"
    static let playerEngineDidTransfer: Event = "PlayerEngineDidTransfer"

    // ===== PreRender Manager 事件 =====
    static let playerPreRenderStarted: Event = "PlayerPreRenderStarted"
    static let playerPreRenderReady: Event = "PlayerPreRenderReady"
    static let playerPreRenderTimeout: Event = "PlayerPreRenderTimeout"

    // ===== Preload 事件 =====
    static let playerPreloadTaskDidFinish: Event = "PlayerPreloadTaskDidFinish"

    // ===== StartTime 事件 =====
    static let playerStartTimeDidResolve: Event = "PlayerStartTimeDidResolve"

    // ===== Gesture 事件 =====
    static let playerGestureSingleTap: Event = "PlayerGestureSingleTap"
    static let playerGestureDoubleTap: Event = "PlayerGestureDoubleTap"
    static let playerGesturePan: Event = "PlayerGesturePan"
    static let playerGesturePinch: Event = "PlayerGesturePinch"
    static let playerGestureLongPress: Event = "PlayerGestureLongPress"

    // ===== Subtitle 事件 =====
    static let playerSubtitleDidChange: Event = "PlayerSubtitleDidChange"
    static let playerSubtitleCueDidUpdate: Event = "PlayerSubtitleCueDidUpdate"

    // ===== Snapshot 事件 =====
    static let playerSnapshotDidCapture: Event = "PlayerSnapshotDidCapture"

    // ===== SpeedPanel 事件 =====
    static let playerSpeedPanelDidShow: Event = "PlayerSpeedPanelDidShow"
    static let playerSpeedPanelDidDismiss: Event = "PlayerSpeedPanelDidDismiss"

    // ===== Showcase 场景级事件 =====
    static let showcaseFeedPageWillChange: Event = "ShowcaseFeedPageWillChange"
    static let showcaseFeedPageDidChange: Event = "ShowcaseFeedPageDidChange"
    static let showcaseFeedDataDidLoad: Event = "ShowcaseFeedDataDidLoad"
    static let showcaseFeedDataDidLoadMore: Event = "ShowcaseFeedDataDidLoadMore"
    static let showcaseFeedCellWillDisplay: Event = "ShowcaseFeedCellWillDisplay"
}
