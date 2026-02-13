//
//  PlayerViewType.swift
//  playerkit
//
//  播放器视图类型定义
//

import Foundation

// MARK: - 播放器视图类型

/// 播放器视图类型枚举
public enum PlayerViewType: String, CaseIterable {
    case backgroundColorView = "PlayerViewTypeBackgroundColorView"
    case gestureView = "PlayerViewTypeGestureView"
    case containerView = "PlayerViewTypeContainerView"
    case controlUnderlayView = "PlayerViewTypeControlUnderlayView"
    case feedGradientView = "PlayerViewTypeFeedGradientView"
    case feedInfoView = "PlayerViewTypeFeedInfoView"
    case feedSocialView = "PlayerViewTypeFeedSocialView"
    case controlView = "PlayerViewTypeControlView"
    case controlOverlayView = "PlayerViewTypeControlOverlayView"
    case progressView = "PlayerViewTypeProgressView"
    case centerPlayButton = "PlayerViewTypeCenterPlayButton"
    case speedButton = "PlayerViewTypeSpeedButton"
    case fullscreenButton = "PlayerViewTypeFullscreenButton"
    case currentTimeLabel = "PlayerViewTypeCurrentTimeLabel"
    case durationLabel = "PlayerViewTypeDurationLabel"
    case bufferProgressView = "PlayerViewTypeBufferProgressView"
    case bottomBarBackground = "PlayerViewTypeBottomBarBackground"
    case toastView = "PlayerViewTypeToastView"
    case debugView = "PlayerViewTypeDebugView"
}

// MARK: - 视图类型扩展

public extension PlayerViewType {
    /// 是否是控制视图类型
    var isControlView: Bool {
        switch self {
        case .controlView:
            return true
        default:
            return false
        }
    }

    /// 是否是进度条类型
    var isProgressView: Bool {
        return self == .progressView
    }
}
