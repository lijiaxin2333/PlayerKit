//
//  File.swift
//  PlayerKit
//
//  Created by jason li  on 2026/2/26.
//

import UIKit
import AVFoundation
// MARK: - 播放器视图

/**
 * 基于 AVPlayerLayer 的播放器渲染视图
 */
public class PlayerEngineRenderView: UIView {

    /**
     * 指定底层使用 AVPlayerLayer, 性能优化, 不用再把PlayerLayer贴在UIView上了, 直接让PlayerLayer作为UIView的Layer
     */
    override public class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    /**
     * AVPlayerLayer 的便捷访问
     */
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    /**
     * 持有的 AVPlayer 引用
     */
    private var playerRef: AVPlayer?
    /**
     * 监听 isReadyForDisplay 的 KVO
     */
    private var displayObservation: NSKeyValueObservation?
    /**
     * 首次准备好显示时的回调
     */
    var onReadyForDisplay: (() -> Void)?

    /**
     * 取消对显示就绪状态的监听
     */
    func cancelDisplayObservation() {
        displayObservation?.invalidate()
        displayObservation = nil
    }

    /**
     * 重新监听 isReadyForDisplay
     */
    func reobserveReadyForDisplay() {
        displayObservation?.invalidate()
        displayObservation = nil
        if playerLayer.isReadyForDisplay {
            onReadyForDisplay?()
            return
        }
        displayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] _, change in
            guard change.newValue == true else { return }
            MainActor.assumeIsolated {
                self?.displayObservation?.invalidate()
                self?.displayObservation = nil
                self?.onReadyForDisplay?()
            }
        }
    }

    /**
     * 设置要绑定的 AVPlayer
     */
    func setPlayer(_ player: AVPlayer?) {
        playerRef = player
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill

        displayObservation?.invalidate()
        displayObservation = nil
        if playerLayer.isReadyForDisplay {
            onReadyForDisplay?()
        } else {
            displayObservation = playerLayer.observe(\.isReadyForDisplay, options: [.new]) { [weak self] _, change in
                guard change.newValue == true else { return }
                MainActor.assumeIsolated {
                    self?.displayObservation?.invalidate()
                    self?.displayObservation = nil
                    self?.onReadyForDisplay?()
                }
            }
        }
    }

    /**
     * 视图加入窗口时重新绑定
     */
    override public func didMoveToWindow() {
        super.didMoveToWindow()
    }

    /**
     * 布局变化时同步 layer 尺寸
     * 注意：layerClass 方案下，UIKit 自动管理，无需手动设置。
     */
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
}
