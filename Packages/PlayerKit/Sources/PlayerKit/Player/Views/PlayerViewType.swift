//
//  PlayerViewType.swift
//  playerkit
//

import Foundation

/** 播放器视图类型枚举，定义播放器中各种视图层级 */
public enum PlayerViewType: String, CaseIterable {
    /** 背景色视图 */
    case backgroundColorView = "PlayerViewTypeBackgroundColorView"
    /** 手势响应视图 */
    case gestureView = "PlayerViewTypeGestureView"
    /** 内容容器视图 */
    case containerView = "PlayerViewTypeContainerView"
    /** 播控下层视图 */
    case controlUnderlayView = "PlayerViewTypeControlUnderlayView"
    /** Feed 流渐变背景视图 */
    case feedGradientView = "PlayerViewTypeFeedGradientView"
    /** Feed 流信息视图 */
    case feedInfoView = "PlayerViewTypeFeedInfoView"
    /** Feed 流社交互动视图 */
    case feedSocialView = "PlayerViewTypeFeedSocialView"
    /** 播控视图 */
    case controlView = "PlayerViewTypeControlView"
    /** 播控上层视图 */
    case controlOverlayView = "PlayerViewTypeControlOverlayView"
    /** 进度条视图 */
    case progressView = "PlayerViewTypeProgressView"
    /** 中央播放按钮 */
    case centerPlayButton = "PlayerViewTypeCenterPlayButton"
    /** 倍速按钮 */
    case speedButton = "PlayerViewTypeSpeedButton"
    /** 全屏按钮 */
    case fullscreenButton = "PlayerViewTypeFullscreenButton"
    /** 当前时间标签 */
    case currentTimeLabel = "PlayerViewTypeCurrentTimeLabel"
    /** 总时长标签 */
    case durationLabel = "PlayerViewTypeDurationLabel"
    /** 缓冲进度视图 */
    case bufferProgressView = "PlayerViewTypeBufferProgressView"
    /** 底栏背景视图 */
    case bottomBarBackground = "PlayerViewTypeBottomBarBackground"
    /** Toast 提示视图 */
    case toastView = "PlayerViewTypeToastView"
    /** 调试信息视图 */
    case debugView = "PlayerViewTypeDebugView"
}

public extension PlayerViewType {
    /** 是否是控制视图类型 */
    var isControlView: Bool {
        switch self {
        case .controlView:
            return true
        default:
            return false
        }
    }

    /** 是否是进度条类型 */
    var isProgressView: Bool {
        return self == .progressView
    }
}
