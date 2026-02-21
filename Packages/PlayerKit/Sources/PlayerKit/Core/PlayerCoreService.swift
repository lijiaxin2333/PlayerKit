//
//  PlayerCoreService.swift
//  playerkit
//
//  PlayerKit Core 服务聚合
//

import Foundation
import AVFoundation
import UIKit


/**
 * Event 扩展，定义 PlayerKit 核心事件
 */
public extension Event {
    /**
     * 播放器引擎已创建（粘性事件）
     */
    static let playerEngineDidCreateSticky: Event = "PlayerEngineDidCreateSticky"
    /**
     * 播放器引擎已改变
     */
    static let playerEngineDidChange: Event = "PlayerEngineDidChange"
    /**
     * 播放状态改变
     */
    static let playerPlaybackStateChanged: Event = "PlayerPlaybackStateChanged"
    /**
     * 准备好显示（粘性事件）
     */
    static let playerReadyForDisplaySticky: Event = "PlayerReadyForDisplaySticky"
    /**
     * 准备播放
     */
    static let playerReadyToPlay: Event = "PlayerReadyToPlay"
    /**
     * 准备播放（粘性事件）
     */
    static let playerReadyToPlaySticky: Event = "PlayerReadyToPlaySticky"
    /**
     * 加载状态改变
     */
    static let playerLoadStateDidChange: Event = "PlayerLoadStateDidChange"
    /**
     * 播放完成
     */
    static let playerPlaybackDidFinish: Event = "PlayerPlaybackDidFinish"
    /**
     * 播放失败
     */
    static let playerPlaybackDidFail: Event = "PlayerPlaybackDidFail"

    /**
     * 进度开始拖动
     */
    static let playerProgressBeginScrubbing: Event = "PlayerProgressBeginScrubbing"
    /**
     * 进度拖动中
     */
    static let playerProgressScrubbing: Event = "PlayerProgressScrubbing"
    /**
     * 进度结束拖动
     */
    static let playerProgressEndScrubbing: Event = "PlayerProgressEndScrubbing"
    /**
     * Slider 触发的 Seek 开始
     */
    static let playerSliderSeekBegin: Event = "PlayerSliderSeekBegin"
    /**
     * Slider 触发的 Seek 结束
     */
    static let playerSliderSeekEnd: Event = "PlayerSliderSeekEnd"
    /**
     * 手势触发的 Seek 开始
     */
    static let playerGestureSeekBegin: Event = "PlayerGestureSeekBegin"
    /**
     * 手势触发的 Seek 结束
     */
    static let playerGestureSeekEnd: Event = "PlayerGestureSeekEnd"
    /**
     * Seek 开始
     */
    static let playerSeekBegin: Event = "PlayerSeekBegin"
    /**
     * Seek 结束
     */
    static let playerSeekEnd: Event = "PlayerSeekEnd"
    /**
     * 开始卡顿
     */
    static let playerPlayingStalledBegin: Event = "PlayerPlayingStalledBegin"
    /**
     * 结束卡顿
     */
    static let playerPlayingStalledEnd: Event = "PlayerPlayingStalledEnd"

    /**
     * 播控模板更新
     */
    static let playerControlViewTemplateChanged: Event = "PlayerControlViewTemplateChanged"
    /**
     * 主动更新模板
     */
    static let playerControlViewTryUpdateTemplate: Event = "PlayerControlViewTryUpdateTemplate"
    /**
     * 播控初次加载完成（粘性事件）
     */
    static let playerControlViewDidLoadSticky: Event = "PlayerControlViewDidLoadSticky"
    /**
     * 播控显示状态更新
     */
    static let playerShowControl: Event = "PlayerShowControl"
    /**
     * 播控锁屏状态更新
     */
    static let playerControlViewDidChangeLock: Event = "PlayerControlViewDidChangeLock"
    /**
     * 单击播控
     */
    static let playerControlViewSingleTap: Event = "PlayerControlViewSingleTap"
    /**
     * 播控 Focus 状态更新
     */
    static let playerControlViewDidChangeFocus: Event = "PlayerControlViewDidChangeFocus"

    /**
     * 全屏状态改变
     */
    static let playerFullScreenStateChanged: Event = "PlayerFullScreenStateChanged"
    /**
     * 将要进入全屏
     */
    static let playerWillEnterFullScreen: Event = "PlayerWillEnterFullScreen"
    /**
     * 已经进入全屏
     */
    static let playerDidEnterFullScreen: Event = "PlayerDidEnterFullScreen"
    /**
     * 将要退出全屏
     */
    static let playerWillExitFullScreen: Event = "PlayerWillExitFullScreen"
    /**
     * 已经退出全屏
     */
    static let playerDidExitFullScreen: Event = "PlayerDidExitFullScreen"

    /**
     * 倍速改变
     */
    static let playerSpeedDidChange: Event = "PlayerSpeedDidChange"

    /**
     * 分辨率改变
     */
    static let playerResolutionDidChange: Event = "PlayerResolutionDidChange"
    /**
     * 获取到分辨率列表
     */
    static let playerDidFetchResolutions: Event = "PlayerDidFetchResolutions"

    /**
     * 音量改变
     */
    static let playerVolumeDidChange: Event = "PlayerVolumeDidChange"
    /**
     * 亮度改变
     */
    static let playerBrightnessDidChange: Event = "PlayerBrightnessDidChange"

    /**
     * 循环状态改变
     */
    static let playerLoopingDidChange: Event = "PlayerLoopingDidChange"

    /**
     * 时间更新
     */
    static let playerTimeDidChange: Event = "PlayerTimeDidChange"
    /**
     * 总时长已设置
     */
    static let playerDurationDidSet: Event = "PlayerDurationDidSet"

    /**
     * 预加载下一个开始
     */
    static let playerPreNextDidStart: Event = "PlayerPreNextDidStart"
    /**
     * 预加载下一个完成
     */
    static let playerPreNextDidFinish: Event = "PlayerPreNextDidFinish"

    /**
     * 应用变为活跃
     */
    static let playerAppDidBecomeActive: Event = "PlayerAppDidBecomeActive"
    /**
     * 应用失去活跃
     */
    static let playerAppDidResignActive: Event = "PlayerAppDidResignActive"

    /**
     * 引擎入队到回收池
     */
    static let playerEngineDidEnqueueToPool: Event = "PlayerEngineDidEnqueueToPool"
    /**
     * 引擎从回收池出队
     */
    static let playerEngineDidDequeueFromPool: Event = "PlayerEngineDidDequeueFromPool"
    /**
     * 回收池已清空
     */
    static let playerEnginePoolDidClear: Event = "PlayerEnginePoolDidClear"

    /**
     * 场景注册
     */
    static let playerSceneDidRegister: Event = "PlayerSceneDidRegister"
    /**
     * 场景注销
     */
    static let playerSceneDidUnregister: Event = "PlayerSceneDidUnregister"
    /**
     * 场景改变
     */
    static let playerSceneDidChange: Event = "PlayerSceneDidChange"

    /**
     * 引擎即将转移
     */
    static let playerEngineWillTransfer: Event = "PlayerEngineWillTransfer"
    /**
     * 引擎已完成转移
     */
    static let playerEngineDidTransfer: Event = "PlayerEngineDidTransfer"

    /**
     * 预渲染开始
     */
    static let playerPreRenderStarted: Event = "PlayerPreRenderStarted"
    /**
     * 预渲染就绪
     */
    static let playerPreRenderReady: Event = "PlayerPreRenderReady"
    /**
     * 预渲染超时
     */
    static let playerPreRenderTimeout: Event = "PlayerPreRenderTimeout"

    /**
     * 预加载任务完成
     */
    static let playerPreloadTaskDidFinish: Event = "PlayerPreloadTaskDidFinish"

    /**
     * 起始时间已解析
     */
    static let playerStartTimeDidResolve: Event = "PlayerStartTimeDidResolve"

    /**
     * 单击手势
     */
    static let playerGestureSingleTap: Event = "PlayerGestureSingleTap"
    /**
     * 双击手势
     */
    static let playerGestureDoubleTap: Event = "PlayerGestureDoubleTap"
    /**
     * 滑动手势
     */
    static let playerGesturePan: Event = "PlayerGesturePan"
    /**
     * 捏合手势
     */
    static let playerGesturePinch: Event = "PlayerGesturePinch"
    /**
     * 长按手势
     */
    static let playerGestureLongPress: Event = "PlayerGestureLongPress"

    /**
     * 字幕改变
     */
    static let playerSubtitleDidChange: Event = "PlayerSubtitleDidChange"
    /**
     * 字幕 cue 更新
     */
    static let playerSubtitleCueDidUpdate: Event = "PlayerSubtitleCueDidUpdate"

    /**
     * 截屏完成
     */
    static let playerSnapshotDidCapture: Event = "PlayerSnapshotDidCapture"

    /**
     * 倍速面板显示
     */
    static let playerSpeedPanelDidShow: Event = "PlayerSpeedPanelDidShow"
    /**
     * 倍速面板关闭
     */
    static let playerSpeedPanelDidDismiss: Event = "PlayerSpeedPanelDidDismiss"

    /**
     * 倍速
     */
    static let playerRateDidChangeSticky: Event = "PlayerRateDidChangeSticky"
}
