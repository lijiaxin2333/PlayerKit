//
//  PlayerPreRenderComp.swift
//  playerkit
//
//  预渲染组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerPreRenderComp: CCLBaseComp, PlayerPreRenderService {

    public typealias ConfigModelType = PlayerPreRenderConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?

    private var _isPreRenderEnabled: Bool = false
    private var prerenderURL: URL?
    private var prerenderPlayerItem: AVPlayerItem?

    // MARK: - PlayerPreRenderService

    public var isPreRenderEnabled: Bool {
        get { _isPreRenderEnabled }
        set { _isPreRenderEnabled = newValue }
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

        guard let config = configModel as? PlayerPreRenderConfigModel else { return }
        _isPreRenderEnabled = config.enabled
    }

    // MARK: - PlayerPreRenderService

    public func prerenderURL(_ url: URL) {
        guard isPreRenderEnabled else {
            print("[PlayerPreRenderComp] 预渲染未启用")
            return
        }

        prerenderURL = url
        print("[PlayerPreRenderComp] 开始预渲染: \(url.lastPathComponent)")

        // 创建 AVAsset 并开始加载
        let asset = AVAsset(url: url)

        // 预加载关键属性
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
                    print("[PlayerPreRenderComp] 预加载失败: \(key)")
                    break
                }
            }

            if isReady {
                print("[PlayerPreRenderComp] 预渲染完成，时长: \(CMTimeGetSeconds(asset.duration))秒")

                // 创建预渲染的播放项（但不关联到播放器）
                let playerItem = AVPlayerItem(asset: asset)
                self.prerenderPlayerItem = playerItem

                // 预加载到内存（播放一小段然后暂停）
                if let player = self.engineService?.avPlayer {
                    player.replaceCurrentItem(with: playerItem)
                    player.preroll(atRate: 1.0) { finished in
                        print("[PlayerPreRenderComp] 预滚动完成: \(finished)")
                    }
                }
            }
        }
    }

    public func cancelPrerender() {
        prerenderURL = nil
        prerenderPlayerItem = nil
        print("[PlayerPreRenderComp] 取消预渲染")
    }

    // MARK: - Public Methods

    /// 获取预渲染的播放项
    public func prerenderedPlayerItem() -> AVPlayerItem? {
        return prerenderPlayerItem
    }

    /// 检查 URL 是否已预渲染
    public func isPrerendered(_ url: URL) -> Bool {
        return prerenderURL == url && prerenderPlayerItem != nil
    }
}
