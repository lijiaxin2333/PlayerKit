//
//  PlayerDataPlugin.swift
//  playerkit
//

import Foundation

/** 播放器数据配置模型 */
public class PlayerDataConfigModel {

    /** 初始数据模型 */
    public var initialDataModel: PlayerDataModel?

    /** 初始化数据配置模型 */
    public init() {}
}

@MainActor
public final class PlayerDataPlugin: BasePlugin, PlayerDataService {

    public typealias ConfigModelType = PlayerDataConfigModel

    public static let cclServiceName = "PlayerDataService"

    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    private var _dataModel: PlayerDataModel = PlayerDataModel()
    private var _isDataReady: Bool = false

    public var dataModel: PlayerDataModel {
        return _dataModel
    }

    public var isDataReady: Bool {
        return _isDataReady
    }

    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerDataConfigModel else { return }

        if let initialModel = configModel.initialDataModel {
            updateDataModel(initialModel)
        }
    }

    public func updateDataModel(_ model: PlayerDataModel) {
        context?.post(PlayerDataModelWillUpdateEvent, object: _dataModel, sender: self)

        _dataModel = model
        _isDataReady = true

        updatePlayerInfo()

        context?.post(PlayerDataModelDidUpdateEvent, object: model, sender: self)
        context?.post(PlayerDataModelChangedEvent, object: model, sender: self)
    }

    public func clearData() {
        _dataModel = PlayerDataModel()
        _isDataReady = false
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    public func updatePlayerInfo() {
        guard let url = _dataModel.videoURL else { return }
        guard engineService?.currentURL != url else { return }
        engineService?.setURL(url)
    }

    public func updateVideoSize(width: Int, height: Int) {
        _dataModel.videoWidth = width
        _dataModel.videoHeight = height
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    public func updateDuration(_ duration: TimeInterval) {
        _dataModel.duration = duration
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }
}
