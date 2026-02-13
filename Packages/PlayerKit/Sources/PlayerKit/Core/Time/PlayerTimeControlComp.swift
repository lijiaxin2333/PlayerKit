//
//  PlayerTimeControlComp.swift
//  playerkit
//
//  时间控制组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerTimeControlComp: CCLBaseComp, PlayerTimeControlService {

    public typealias ConfigModelType = PlayerTimeControlConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?


    // MARK: - PlayerTimeControlService

    public var currentTime: TimeInterval {
        return engineService?.currentTime ?? 0
    }

    public var duration: TimeInterval {
        return engineService?.duration ?? 0
    }

    public var remainingTime: TimeInterval {
        let dur = duration
        return dur > 0 ? max(0, dur - currentTime) : 0
    }

    public var watchedDuration: TimeInterval {
        return currentTime
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerTimeControlService

    public func formatTime(_ time: TimeInterval, style: PlayerTimeStyle = .standard) -> String {
        let totalSeconds = Int(max(0, time))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        switch style {
        case .standard:
            if hours > 0 {
                return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%02d:%02d", minutes, seconds)
            }
        case .full:
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        case .short:
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        case .verbose:
            if hours > 0 {
                return "\(hours)小时\(minutes)分\(seconds)秒"
            } else if minutes > 0 {
                return "\(minutes)分\(seconds)秒"
            } else {
                return "\(seconds)秒"
            }
        }
    }

    public func currentTimeString(style: PlayerTimeStyle = .standard) -> String {
        let config = configModel as? PlayerTimeControlConfigModel
        let resolvedStyle = style == .standard ? (config?.defaultStyle ?? .standard) : style
        return formatTime(currentTime, style: resolvedStyle)
    }

    public func durationString(style: PlayerTimeStyle = .standard) -> String {
        let config = configModel as? PlayerTimeControlConfigModel
        let resolvedStyle = style == .standard ? (config?.defaultStyle ?? .standard) : style
        return formatTime(duration, style: resolvedStyle)
    }

    public func remainingTimeString(style: PlayerTimeStyle = .standard) -> String {
        let config = configModel as? PlayerTimeControlConfigModel
        let resolvedStyle = style == .standard ? (config?.defaultStyle ?? .standard) : style
        return formatTime(remainingTime, style: resolvedStyle)
    }

    public func timeProgressString(style: PlayerTimeStyle = .standard) -> String {
        let config = configModel as? PlayerTimeControlConfigModel
        let resolvedStyle = style == .standard ? (config?.defaultStyle ?? .standard) : style
        return "\(currentTimeString(style: resolvedStyle)) / \(durationString(style: resolvedStyle))"
    }
}
