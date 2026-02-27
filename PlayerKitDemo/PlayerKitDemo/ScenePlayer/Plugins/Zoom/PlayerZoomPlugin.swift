//
//  PlayerZoomPlugin.swift
//  PlayerKit
//
//  自由缩放插件实现
//

import Foundation
import UIKit
import BizPlayerKit

// MARK: - 缩放视图

/**
 * 支持自由缩放的播放器视图容器
 */
public class PlayerZoomableView: UIView {

    // MARK: - Properties

    /// 内容视图（播放器渲染视图）
    public private(set) var contentView: UIView?

    /// 缩放比例
    public var scale: CGFloat = 1.0 {
        didSet {
            applyTransform()
        }
    }

    /// 内容偏移
    public var contentOffset: CGPoint = .zero {
        didSet {
            applyTransform()
        }
    }

    /// 是否开启智能满屏
    public var isAspectFillEnabled: Bool = false {
        didSet {
            if isAspectFillEnabled {
                applyAspectFill()
            } else {
                resetToOriginal()
            }
        }
    }

    /// 最小缩放比例
    public var minimumScale: CGFloat = 0.5

    /// 最大缩放比例
    public var maximumScale: CGFloat = 3.0

    /// 是否支持旋转
    public var rotationEnabled: Bool = true

    // MARK: - Gesture Properties

    private var initialScale: CGFloat = 1.0
    private var initialOffset: CGPoint = .zero
    private var initialTouchPoints: [CGPoint] = []
    private var initialDistance: CGFloat = 0
    private var initialCenter: CGPoint = .zero
    private var initialAngle: CGFloat = 0

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
        clipsToBounds = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
        clipsToBounds = false
    }

    // MARK: - Setup

    /// 设置内容视图
    public func setContentView(_ view: UIView) {
        contentView?.removeFromSuperview()
        contentView = view
        if let content = contentView {
            addSubview(content)
            content.frame = bounds
            content.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }

    private func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        addGestureRecognizer(pinchGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        addGestureRecognizer(panGesture)

        // 双指旋转
        if rotationEnabled {
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            rotationGesture.delegate = self
            addGestureRecognizer(rotationGesture)
        }
    }

    // MARK: - Transform

    private func applyTransform() {
        guard let content = contentView else { return }

        let transform = CGAffineTransform(scaleX: scale, y: scale)
        content.transform = transform

        let scaledSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
        let centerX = (bounds.width - scaledSize.width) / 2 + contentOffset.x
        let centerY = (bounds.height - scaledSize.height) / 2 + contentOffset.y
        content.center = CGPoint(x: bounds.midX + centerX, y: bounds.midY + centerY)
    }

    private func applyAspectFill() {
        guard let content = contentView else { return }

        let contentAspect = content.bounds.width / content.bounds.height
        let containerAspect = bounds.width / bounds.height

        if contentAspect < containerAspect {
            // 内容更高，需要水平填满，垂直裁剪
            scale = bounds.width / content.bounds.width
        } else {
            // 内容更宽，需要垂直填满，水平裁剪
            scale = bounds.height / content.bounds.height
        }

        contentOffset = .zero
        applyTransform()
    }

    private func resetToOriginal() {
        scale = 1.0
        contentOffset = .zero
        applyTransform()
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        if isAspectFillEnabled {
            applyAspectFill()
        }
        applyTransform()
    }

    // MARK: - Gestures

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialScale = scale
            initialDistance = gesture.scale
        case .changed:
            let newScale = initialScale * gesture.scale
            scale = min(maximumScale, max(minimumScale, newScale))
            onZoomChanged?(PlayerZoomState(mode: .custom, scale: scale, fromGesture: true))
        case .ended, .cancelled:
            snapToNearestMode()
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard scale > 1.0 else { return }

        switch gesture.state {
        case .began:
            initialOffset = contentOffset
        case .changed:
            let translation = gesture.translation(in: self)
            let scaledSize = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let maxOffsetX = (scaledSize.width - bounds.width) / 2
            let maxOffsetY = (scaledSize.height - bounds.height) / 2

            var newOffsetX = initialOffset.x + translation.x
            var newOffsetY = initialOffset.y + translation.y

            // 限制偏移范围
            newOffsetX = min(maxOffsetX, max(-maxOffsetX, newOffsetX))
            newOffsetY = min(maxOffsetY, max(-maxOffsetY, newOffsetY))

            contentOffset = CGPoint(x: newOffsetX, y: newOffsetY)
            onZoomChanged?(PlayerZoomState(mode: .custom, scale: scale, fromGesture: true))
        default:
            break
        }
    }

    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard rotationEnabled else { return }

        switch gesture.state {
        case .began:
            initialAngle = atan2(contentView?.transform.b ?? 0, contentView?.transform.a ?? 1)
        case .changed:
            let angle = initialAngle + gesture.rotation
            contentView?.transform = CGAffineTransform(rotationAngle: angle).scaledBy(x: scale, y: scale)
        default:
            break
        }
    }

    private func snapToNearestMode() {
        // 靠近1.0时恢复原始大小
        if abs(scale - 1.0) < 0.15 {
            scale = 1.0
            contentOffset = .zero
            onZoomChanged?(PlayerZoomState(mode: .noZoom, scale: 1.0, fromGesture: true))
        }
        applyTransform()
    }

    // MARK: - Callbacks

    /// 缩放状态变化回调
    public var onZoomChanged: ((PlayerZoomState) -> Void)?
}

// MARK: - UIGestureRecognizerDelegate

extension PlayerZoomableView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - Zoom Plugin

/**
 * 自由缩放插件实现
 */
@MainActor
public final class PlayerZoomPlugin: BasePlugin, PlayerZoomService {

    public typealias ConfigModelType = PlayerZoomConfigModel

    // MARK: - Properties

    /// 缩放视图容器
    private var zoomableView: PlayerZoomableView?

    /// 是否开启智能满屏
    private var _isTurnOnAspectFill: Bool = false

    /// 是否继承智能满屏状态
    private var aspectFillStateInherit: Bool = true

    /// 全屏时是否限制底部滑动
    private var fullScreenStickBottomSlide: Bool = false

    /// 服务依赖
    @PlayerPlugin var engineService: PlayerEngineCoreService?

    // MARK: - PlayerZoomService

    /// 类型化的配置模型
    private var typedConfigModel: PlayerZoomConfigModel? {
        configModel as? PlayerZoomConfigModel
    }

    public var disableZoom: Bool {
        typedConfigModel?.disableZoom ?? false
    }

    public var disableFreeZoomGesture: Bool {
        typedConfigModel?.disableFreeZoomGesture ?? false
    }

    public var zoomMode: PlayerZoomMode {
        guard let zoomable = zoomableView else { return .noZoom }
        if zoomable.isAspectFillEnabled {
            return .aspectFill
        } else if abs(zoomable.scale - 1.0) < 0.01 {
            return .noZoom
        } else {
            return .custom
        }
    }

    public var scale: CGFloat {
        zoomableView?.scale ?? 1.0
    }

    public var isInAspectFill: Bool {
        zoomMode == .aspectFill
    }

    public var isTurnOnAspectFill: Bool {
        _isTurnOnAspectFill
    }

    public func canZoomToAspectFill() -> Bool {
        !disableZoom && zoomableView != nil
    }

    public func setAspectFillEnable(_ enable: Bool, animated: Bool) {
        guard !disableZoom else { return }
        guard _isTurnOnAspectFill != enable else { return }

        _isTurnOnAspectFill = enable
        zoomableView?.isAspectFillEnabled = enable

        if animated {
            UIView.animate(withDuration: 0.25) {
                self.zoomableView?.layoutIfNeeded()
            }
        }

        context?.post(.playerAspectFillDidChanged, object: enable, sender: self)
    }

    public func setScale(_ scale: CGFloat) {
        zoomableView?.scale = scale
        onZoomStateChanged(fromGesture: false)
    }

    public func setAspectFillStateInherit(_ enable: Bool) {
        aspectFillStateInherit = enable
    }

    public func setFullScreenStickBottomSlide(_ fullScreenStickBottomSlide: Bool) {
        self.fullScreenStickBottomSlide = fullScreenStickBottomSlide
    }

    // MARK: - Plugin Lifecycle

    public override func pluginDidLoad(_ context: ContextProtocol) {
        super.pluginDidLoad(context)
        setupZoomableView()
        observeEvents()
    }

    public override func pluginWillUnload(_ context: ContextProtocol) {
        super.pluginWillUnload(context)
        zoomableView?.removeFromSuperview()
        zoomableView = nil
    }

    public override func config(_ configModel: Any?) {
        super.config(configModel)

        guard let config = configModel as? PlayerZoomConfigModel else { return }

        zoomableView?.minimumScale = config.minimumScale
        zoomableView?.maximumScale = config.maximumScale
        zoomableView?.rotationEnabled = config.rotationEnabled

        if config.disableFreeZoomGesture {
            zoomableView?.isUserInteractionEnabled = false
        }

        if config.disableZoom && _isTurnOnAspectFill {
            setAspectFillEnable(false, animated: false)
        }
    }

    // MARK: - Private

    private func setupZoomableView() {
        let zoomable = PlayerZoomableView(frame: .zero)
        zoomable.minimumScale = typedConfigModel?.minimumScale ?? 0.5
        zoomable.maximumScale = typedConfigModel?.maximumScale ?? 3.0
        zoomable.rotationEnabled = typedConfigModel?.rotationEnabled ?? true
        zoomable.onZoomChanged = { [weak self] state in
            self?.onZoomStateChanged(fromGesture: state.fromGesture)
        }
        self.zoomableView = zoomable

        // 监听引擎视图创建
        context?.add(self, event: .playerEngineDidCreateSticky) { [weak self] _, _ in
            self?.attachToPlayerView()
        }

        // 尝试立即附加
        attachToPlayerView()
    }

    private func attachToPlayerView() {
        guard let playerView = engineService?.playerView else { return }
        guard let zoomable = zoomableView else { return }

        // 避免重复添加
        if zoomable.superview != nil && zoomable.contentView === playerView {
            return
        }

        // 将播放器视图包装到缩放容器中
        if playerView.superview != nil && playerView.superview !== zoomable {
            let superview = playerView.superview
            zoomable.frame = playerView.frame
            zoomable.autoresizingMask = playerView.autoresizingMask

            playerView.removeFromSuperview()
            zoomable.setContentView(playerView)

            superview?.addSubview(zoomable)
        }

        context?.post(.playerEngineDidCreateRenderView, object: zoomable, sender: self)
    }

    private func observeEvents() {
        // 数据变化时，根据继承设置决定是否关闭智能满屏
        context?.add(self, event: .playerDataModelWillUpdate) { [weak self] _, _ in
            guard let self = self, !self.aspectFillStateInherit else { return }
            self.setAspectFillEnable(false, animated: false)
        }

        // 播放开始时，确保智能满屏生效
        context?.add(self, event: .playerPlaybackStateChanged) { [weak self] object, _ in
            guard let self = self else { return }
            if let state = object as? PlayerPlaybackState, state == .playing {
                if self._isTurnOnAspectFill {
                    self.zoomableView?.isAspectFillEnabled = true
                }
            }
        }
    }

    private func onZoomStateChanged(fromGesture: Bool) {
        let state = PlayerZoomState(mode: zoomMode, scale: scale, fromGesture: fromGesture)
        context?.post(.playerZoomStateDidChanged, object: state, sender: self)
    }
}
