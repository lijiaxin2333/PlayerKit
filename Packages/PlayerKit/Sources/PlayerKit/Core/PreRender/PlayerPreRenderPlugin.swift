//
//  PlayerPreRenderPlugin.swift
//  playerkit
//
//  预渲染组件实现
//

import Foundation
import AVFoundation
import UIKit

/**
 * 预渲染插件，提供视频 URL 的预加载与预渲染能力
 */
@MainActor
public final class PlayerPreRenderPlugin: BasePlugin, PlayerPreRenderService {

    public typealias ConfigModelType = PlayerPreRenderConfigModel

    /** 引擎核心服务依赖 */
    @PlayerPlugin private var engineService: PlayerEngineCoreService?

    /** 是否启用预渲染 */
    private var _isPreRenderEnabled: Bool = false
    /** 当前预渲染的 URL */
    private var prerenderURL: URL?
    /** 预渲染完成的播放项 */
    private var prerenderPlayerItem: AVPlayerItem?

    /** 是否启用预渲染 */
    public var isPreRenderEnabled: Bool {
        get { _isPreRenderEnabled }
        set { _isPreRenderEnabled = newValue }
    }

    /**
     * 初始化插件
     */
    public required override init() {
        super.init()
    }

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerPreRenderConfigModel else { return }
        _isPreRenderEnabled = config.enabled
    }

    /**
     * 对指定 URL 进行预渲染
     */
    public func prerenderURL(_ url: URL) {
        guard isPreRenderEnabled else {
            print("[PlayerPreRenderPlugin] 预渲染未启用")
            return
        }

        prerenderURL = url
        print("[PlayerPreRenderPlugin] 开始预渲染: \(url.lastPathComponent)")

        let asset = AVAsset(url: url)

        let keys = [
            "playable",
            "duration",
            "preferredRate",
            "preferredVolume",
            "naturalSize"
        ]

        asset.loadValuesAsynchronously(forKeys: keys) { [weak self] in
            guard let self = self else { return }

            var isReady = true
            for key in keys {
                let status = asset.statusOfValue(forKey: key, error: nil)
                if status == .failed {
                    isReady = false
                    print("[PlayerPreRenderPlugin] 预加载失败: \(key)")
                    break
                }
            }

            if isReady {
                print("[PlayerPreRenderPlugin] 预渲染完成，时长: \(CMTimeGetSeconds(asset.duration))秒")

                let playerItem = AVPlayerItem(asset: asset)
                self.prerenderPlayerItem = playerItem

                if let player = self.engineService?.avPlayer {
                    player.replaceCurrentItem(with: playerItem)
                    player.preroll(atRate: 1.0) { finished in
                        print("[PlayerPreRenderPlugin] 预滚动完成: \(finished)")
                    }
                }
            }
        }
    }

    /**
     * 取消当前预渲染
     */
    public func cancelPrerender() {
        prerenderURL = nil
        prerenderPlayerItem = nil
        print("[PlayerPreRenderPlugin] 取消预渲染")
    }

    /**
     * 获取预渲染完成的播放项
     */
    public func prerenderedPlayerItem() -> AVPlayerItem? {
        return prerenderPlayerItem
    }

    /**
     * 检查指定 URL 是否已预渲染
     */
    public func isPrerendered(_ url: URL) -> Bool {
        return prerenderURL == url && prerenderPlayerItem != nil
    }
}
