//
//  PlayerEventDefine.swift
//  playerkit
//
//  PlayerKit 核心层事件定义
//

import Foundation

/**
 * Event 扩展，定义 PlayerKit 核心层事件
 */
public extension Event {

    // MARK: - Engine Events

    /// 播放器引擎已创建（粘性事件）
    static let playerEngineDidCreateSticky: Event = "PlayerEngineDidCreateSticky"

    /// 播放器引擎已改变
    static let playerEngineDidChange: Event = "PlayerEngineDidChange"

    /// 播放器引擎视图变化（渲染视图变化）
    static let playerEngineViewDidChanged: Event = "PlayerEngineViewDidChanged"

    /// 播放器引擎创建渲染视图
    static let playerEngineDidCreateRenderView: Event = "PlayerEngineDidCreateRenderView"

    /// 获取到引擎模型（如 VID 拉取到 VideoEngineModel）
    static let playerDidFetchEngineModel: Event = "PlayerDidFetchEngineModel"

    // MARK: - Playback Events

    /// 播放状态改变
    static let playerPlaybackStateChanged: Event = "PlayerPlaybackStateChanged"

    /// 准备好显示（粘性事件）
    static let playerReadyForDisplaySticky: Event = "PlayerReadyForDisplaySticky"

    /// 准备播放
    static let playerReadyToPlay: Event = "PlayerReadyToPlay"

    /// 准备播放（粘性事件）
    static let playerReadyToPlaySticky: Event = "PlayerReadyToPlaySticky"

    /// 加载状态改变
    static let playerLoadStateDidChange: Event = "PlayerLoadStateDidChange"

    /// 播放完成
    static let playerPlaybackDidFinish: Event = "PlayerPlaybackDidFinish"

    /// 播放失败
    static let playerPlaybackDidFail: Event = "PlayerPlaybackDidFail"

    /// 开始卡顿
    static let playerPlayingStalledBegin: Event = "PlayerPlayingStalledBegin"

    /// 结束卡顿
    static let playerPlayingStalledEnd: Event = "PlayerPlayingStalledEnd"

    // MARK: - Progress & Seek Events

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

    // MARK: - Speed Events

    /// 倍速改变
    static let playerSpeedDidChange: Event = "PlayerSpeedDidChange"

    /// 倍速（粘性事件）
    static let playerRateDidChangeSticky: Event = "PlayerRateDidChangeSticky"

    // MARK: - Time Events

    /// 时间更新
    static let playerTimeDidChange: Event = "PlayerTimeDidChange"

    /// 总时长已设置
    static let playerDurationDidSet: Event = "PlayerDurationDidSet"

    /// 起始时间已解析
    static let playerStartTimeDidResolve: Event = "PlayerStartTimeDidResolve"

    // MARK: - Loop Events

    /// 循环状态改变
    static let playerLoopingDidChange: Event = "PlayerLoopingDidChange"

    // MARK: - Volume & Brightness Events

    /// 音量改变
    static let playerVolumeDidChange: Event = "PlayerVolumeDidChange"

    /// 亮度改变
    static let playerBrightnessDidChange: Event = "PlayerBrightnessDidChange"

    // MARK: - Resolution Events

    /// 分辨率改变
    static let playerResolutionDidChange: Event = "PlayerResolutionDidChange"

    /// 获取到分辨率列表
    static let playerDidFetchResolutions: Event = "PlayerDidFetchResolutions"

    // MARK: - App Lifecycle Events

    /// 应用变为活跃
    static let playerAppDidBecomeActive: Event = "PlayerAppDidBecomeActive"

    /// 应用失去活跃
    static let playerAppDidResignActive: Event = "PlayerAppDidResignActive"

    // MARK: - Engine Pool Events

    /// 引擎入队到回收池
    static let playerEngineDidEnqueueToPool: Event = "PlayerEngineDidEnqueueToPool"

    /// 引擎从回收池出队
    static let playerEngineDidDequeueFromPool: Event = "PlayerEngineDidDequeueFromPool"

    /// 回收池已清空
    static let playerEnginePoolDidClear: Event = "PlayerEnginePoolDidClear"

    /// 引擎即将转移
    static let playerEngineWillTransfer: Event = "PlayerEngineWillTransfer"

    /// 引擎已完成转移
    static let playerEngineDidTransfer: Event = "PlayerEngineDidTransfer"

    // MARK: - PreRender Events

    /// 预渲染开始
    static let playerPreRenderStarted: Event = "PlayerPreRenderStarted"

    /// 预渲染就绪
    static let playerPreRenderReady: Event = "PlayerPreRenderReady"

    /// 预渲染超时
    static let playerPreRenderTimeout: Event = "PlayerPreRenderTimeout"

    /// 预加载任务完成
    static let playerPreloadTaskDidFinish: Event = "PlayerPreloadTaskDidFinish"

    // MARK: - Buffer Events

    /// 起播前开始加载缓存
    static let playerStartPlayLoadBufferBegin: Event = "PlayerStartPlayLoadBufferBegin"

    /// 起播前结束加载缓存
    static let playerStartPlayLoadBufferEnd: Event = "PlayerStartPlayLoadBufferEnd"

    // MARK: - Scale Events

    /// 缩放模式改变
    static let playerScaleModeChanged: Event = "PlayerScaleModeChanged"

    // MARK: - Scene Events

    /// 场景注册
    static let playerSceneDidRegister: Event = "PlayerSceneDidRegister"

    /// 场景注销
    static let playerSceneDidUnregister: Event = "PlayerSceneDidUnregister"

    /// 场景改变
    static let playerSceneDidChange: Event = "PlayerSceneDidChange"

    // MARK: - Data Events

    /// 数据模型即将更新
    static let playerDataModelWillUpdate: Event = "PlayerDataModelWillUpdateEvent"

    /// 数据模型已更新（粘性事件）
    static let playerDataModelDidUpdateSticky: Event = "PlayerDataModelDidUpdateSticky"

    // MARK: - Snapshot Events

    /// 截屏完成
    static let playerSnapshotDidCapture: Event = "PlayerSnapshotDidCapture"
}
