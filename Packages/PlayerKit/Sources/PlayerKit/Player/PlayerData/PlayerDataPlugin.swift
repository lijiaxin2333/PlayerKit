//
//  PlayerDataPlugin.swift
//  playerkit
//
//  播放器数据组件
//

import Foundation

// MARK: - 播放器数据配置模型

public class PlayerDataConfigModel {

    /// 初始数据模型
    public var initialDataModel: PlayerDataModel?

    public init() {}
}

// MARK: - 播放器数据组件

/// 播放器数据组件 - 管理播放器数据
@MainActor
public final class PlayerDataPlugin: BasePlugin, PlayerDataService {

    public typealias ConfigModelType = PlayerDataConfigModel

    // MARK: - 服务名称

    public static let cclServiceName = "PlayerDataService"

    // MARK: - Properties

    private var _dataModel: PlayerDataModel = PlayerDataModel()
    private var _isDataReady: Bool = false

    // MARK: - PlayerDataService

    public var dataModel: PlayerDataModel {
        return _dataModel
    }

    public var isDataReady: Bool {
        return _isDataReady
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        print("[PlayerDataPlugin] 组件已加载")
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerDataConfigModel else { return }

        if let initialModel = configModel.initialDataModel {
            updateDataModel(initialModel)
        }
    }

    // MARK: - PlayerDataService

    public func updateDataModel(_ model: PlayerDataModel) {
        // 发送即将更新事件
        context?.post(PlayerDataModelWillUpdateEvent, object: _dataModel, sender: self)

        _dataModel = model
        _isDataReady = true

        // 发送已更新事件
        context?.post(PlayerDataModelDidUpdateEvent, object: model, sender: self)
        context?.post(PlayerDataModelChangedEvent, object: model, sender: self)

        print("[PlayerDataPlugin] 数据模型已更新: \(model.title ?? "(无标题)")")
    }

    public func setVideoURL(_ url: URL?) {
        _dataModel.videoURL = url
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    public func setVid(_ vid: String?) {
        _dataModel.vid = vid
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    public func getVideoURL() -> URL? {
        return _dataModel.videoURL
    }

    public func getVideoSize() -> (width: Int, height: Int) {
        return (_dataModel.videoWidth, _dataModel.videoHeight)
    }

    public func clearData() {
        _dataModel = PlayerDataModel()
        _isDataReady = false
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
        print("[PlayerDataPlugin] 数据已清除")
    }

    // MARK: - Public Methods

    /// 更新视频尺寸
    public func updateVideoSize(width: Int, height: Int) {
        _dataModel.videoWidth = width
        _dataModel.videoHeight = height
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    /// 更新视频时长
    public func updateDuration(_ duration: TimeInterval) {
        _dataModel.duration = duration
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }
}
