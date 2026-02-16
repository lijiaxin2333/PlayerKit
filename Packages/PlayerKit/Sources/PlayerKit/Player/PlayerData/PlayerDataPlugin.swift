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

/** 播放器数据插件，管理播放器的数据模型和数据变更事件 */
@MainActor
public final class PlayerDataPlugin: BasePlugin, PlayerDataService {

    /** 配置模型类型 */
    public typealias ConfigModelType = PlayerDataConfigModel

    /** 服务名称 */
    public static let cclServiceName = "PlayerDataService"

    /** 内部数据模型 */
    private var _dataModel: PlayerDataModel = PlayerDataModel()
    /** 数据是否已准备就绪 */
    private var _isDataReady: Bool = false

    /** 当前数据模型 */
    public var dataModel: PlayerDataModel {
        return _dataModel
    }

    /** 数据是否已准备就绪 */
    public var isDataReady: Bool {
        return _isDataReady
    }

    /** 必须的初始化方法 */
    public required override init() {
        super.init()
    }

    /** 插件加载完成回调 */
    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        print("[PlayerDataPlugin] 组件已加载")
    }

    /** 配置插件，支持初始数据模型设置 */
    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let configModel = configModel as? PlayerDataConfigModel else { return }

        if let initialModel = configModel.initialDataModel {
            updateDataModel(initialModel)
        }
    }

    /** 更新数据模型，发送即将更新和已更新事件 */
    public func updateDataModel(_ model: PlayerDataModel) {
        context?.post(PlayerDataModelWillUpdateEvent, object: _dataModel, sender: self)

        _dataModel = model
        _isDataReady = true

        context?.post(PlayerDataModelDidUpdateEvent, object: model, sender: self)
        context?.post(PlayerDataModelChangedEvent, object: model, sender: self)

        print("[PlayerDataPlugin] 数据模型已更新: \(model.title ?? "(无标题)")")
    }

    /** 设置视频 URL 并发送数据变更事件 */
    public func setVideoURL(_ url: URL?) {
        _dataModel.videoURL = url
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    /** 设置视频 ID 并发送数据变更事件 */
    public func setVid(_ vid: String?) {
        _dataModel.vid = vid
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    /** 获取当前视频 URL */
    public func getVideoURL() -> URL? {
        return _dataModel.videoURL
    }

    /** 获取视频尺寸 */
    public func getVideoSize() -> (width: Int, height: Int) {
        return (_dataModel.videoWidth, _dataModel.videoHeight)
    }

    /** 清除所有数据并重置状态 */
    public func clearData() {
        _dataModel = PlayerDataModel()
        _isDataReady = false
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
        print("[PlayerDataPlugin] 数据已清除")
    }

    /** 更新视频尺寸 */
    public func updateVideoSize(width: Int, height: Int) {
        _dataModel.videoWidth = width
        _dataModel.videoHeight = height
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }

    /** 更新视频时长 */
    public func updateDuration(_ duration: TimeInterval) {
        _dataModel.duration = duration
        context?.post(PlayerDataModelChangedEvent, object: _dataModel, sender: self)
    }
}
