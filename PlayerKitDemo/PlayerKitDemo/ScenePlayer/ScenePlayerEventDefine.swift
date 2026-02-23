//
//  ScenePlayerEventDefine.swift
//  PlayerKitDemo
//
//  场景层事件定义
//

import Foundation
import PlayerKit

/**
 * Event 扩展，定义场景层 UI 相关事件
 */
public extension Event {

    // MARK: - Control View Events

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

    // MARK: - FullScreen Events

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

    // MARK: - Gesture Events

    /// 单击手势
    static let playerGestureSingleTap: Event = "PlayerGestureSingleTap"

    /// 双击手势
    static let playerGestureDoubleTap: Event = "PlayerGestureDoubleTap"

    /// 滑动手势
    static let playerGesturePan: Event = "PlayerGesturePan"

    /// 捏合手势
    static let playerGesturePinch: Event = "PlayerGesturePinch"

    /// 长按手势
    static let playerGestureLongPress: Event = "PlayerGestureLongPress"

    // MARK: - Subtitle Events

    /// 字幕改变
    static let playerSubtitleDidChange: Event = "PlayerSubtitleDidChange"

    /// 字幕 cue 更新
    static let playerSubtitleCueDidUpdate: Event = "PlayerSubtitleCueDidUpdate"

    // MARK: - Speed Panel Events

    /// 倍速面板显示
    static let playerSpeedPanelDidShow: Event = "PlayerSpeedPanelDidShow"

    /// 倍速面板关闭
    static let playerSpeedPanelDidDismiss: Event = "PlayerSpeedPanelDidDismiss"

    // MARK: - Zoom Events

    /// 自由缩放状态变化
    static let playerZoomStateDidChanged: Event = "PlayerZoomStateDidChanged"

    /// 智能满屏开关变化
    static let playerAspectFillDidChanged: Event = "PlayerAspectFillDidChanged"
}
