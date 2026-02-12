//
//  PlayerPreNextComp.swift
//  playerkit
//
//  预加载下一个组件实现
//

import Foundation
import AVFoundation
import UIKit

@MainActor
public final class PlayerPreNextComp: CCLBaseComp, PlayerPreNextService {

    public typealias ConfigModelType = PlayerPreNextConfigModel

    // MARK: - Properties

    @CCLService(serviceType: PlayerEngineCoreService.self) private var engineService: PlayerEngineCoreService?
    @CCLService(serviceType: PlayerProcessService.self) private var processService: PlayerProcessService?

    private var _nextItem: PlayerPreNextItem?
    private var _isPreloading: Bool = false
    private var _preloadProgress: Double = 0
    private var prerenderPlayerItem: AVPlayerItem?

    // MARK: - PlayerPreNextService

    public var nextItem: PlayerPreNextItem? {
        get { _nextItem }
        set {
            _nextItem = newValue
            let config = configModel as? PlayerPreNextConfigModel
            if config?.autoPreload == true {
                startPreload()
            }
        }
    }

    public var isPreloading: Bool {
        get { _isPreloading }
        set { _isPreloading = newValue }
    }

    public var preloadProgress: Double {
        get { _preloadProgress }
        set { _preloadProgress = newValue }
    }

    // MARK: - Initialization

    public required override init() {
        super.init()
    }

    // MARK: - Component Lifecycle

    public override func componentDidLoad(_ context: CCLContextProtocol) {
        super.componentDidLoad(context)

        // 监听进度变化，触发预加载
        self.context?.add(self, event: .playerTimeDidChange) { [weak self] _, _ in
            self?.checkPreloadThreshold()
        }
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)
    }

    // MARK: - PlayerPreNextService

    public func setNextItem(_ item: PlayerPreNextItem?) {
        nextItem = item
    }

    public func startPreload() {
        guard let item = _nextItem, !_isPreloading else {
            print("[PlayerPreNextComp] 预加载失败: 无下一个视频或正在预加载")
            return
        }

        _isPreloading = true
        _preloadProgress = 0
        context?.post(.playerPreNextDidStart, object: item, sender: self)

        print("[PlayerPreNextComp] 开始预加载下一个视频: \(item.title ?? "无标题")")

        // 创建 AVAsset 并开始加载
        let asset = AVAsset(url: item.url)

        // 加载播放属性
        asset.loadValuesAsynchronously(forKeys: ["playable", "duration"]) { [weak self] in
            guard let self = self else { return }

            let playable = asset.isPlayable
            let duration = CMTimeGetSeconds(asset.duration)

            if playable {
                print("[PlayerPreNextComp] 预加载成功，时长: \(duration)秒")

                // 创建预加载的播放项
                let playerItem = AVPlayerItem(asset: asset)
                self.prerenderPlayerItem = playerItem

                // 模拟预加载进度
                self.simulatePreloadProgress()
            } else {
                print("[PlayerPreNextComp] 预加载失败: 视频不可播放")
                self._isPreloading = false
            }
        }
    }

    public func cancelPreload() {
        _isPreloading = false
        _preloadProgress = 0
        prerenderPlayerItem = nil
        print("[PlayerPreNextComp] 取消预加载")
    }

    // MARK: - Public Methods

    /// 获取预加载的播放项
    public func preloadedPlayerItem() -> AVPlayerItem? {
        return prerenderPlayerItem
    }

    // MARK: - Private Methods

    private func checkPreloadThreshold() {
        guard let config = configModel as? PlayerPreNextConfigModel,
              config.autoPreload,
              let process = processService else { return }

        if process.progress >= config.preloadThreshold {
            startPreload()
        }
    }

    private func simulatePreloadProgress() {
        // 模拟预加载进度（实际应使用 AVAssetResourceLoader 或监听加载状态）
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self._preloadProgress += 0.1

            if self._preloadProgress >= 1.0 {
                timer.invalidate()
                self._isPreloading = false
                self._preloadProgress = 1.0
                self.context?.post(.playerPreNextDidFinish, object: self._nextItem, sender: self)
                print("[PlayerPreNextComp] 预加载完成")
            }
        }
    }
}
