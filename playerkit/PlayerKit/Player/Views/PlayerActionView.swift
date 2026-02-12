//
//  PlayerActionView.swift
//  playerkit
//
//  播放器交互视图 - 管理视图层级顺序
//

import UIKit
import Foundation

// MARK: - 播放器交互视图

/// 播放器交互视图 - 根据 viewType 按顺序插入子视图
@MainActor
public final class PlayerActionView: UIView, PlayerActionViewProtocol {

    // MARK: - Properties

    /// 视图类型列表（定义层级顺序，index 越小层级越低）
    private var viewTypeList: [PlayerViewType] = [
        .backgroundColorView,
        .gestureView,
        .containerView,
        .controlUnderlayView,
        .feedGradientView,
        .feedInfoView,
        .feedSocialView,
        .controlView,
        .controlOverlayView,
        .progressView,
        .toastView,
        .debugView,
    ]

    /// 有序子视图列表
    private var orderedSubviews: [UIView] = []

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    // MARK: - Public Methods

    /// 添加视图到指定层级
    /// - Parameters:
    ///   - view: 要添加的视图
    ///   - viewType: 视图类型
    public func addSubview(_ view: UIView, viewType: PlayerViewType) {

        // 避免重复添加
        if orderedSubviews.contains(where: { $0 === view }) {
            return
        }

        // 设置视图类型标签
        view.playerViewType = viewType

        // 查 viewType 在列表中的索引
        guard let viewTypeIndex = viewTypeList.firstIndex(of: viewType) else {
            // 如果不在预定义列表中，添加到最上层
            addSubview(view)
            orderedSubviews.append(view)
            return
        }

        // 根据 viewTypeList 中的顺序，找到合适的插入位置
        var insertIndex = viewTypeList.count

        for (index, existingView) in orderedSubviews.enumerated() {
            guard let existingType = existingView.playerViewType else { continue }
            guard let existingIndex = viewTypeList.firstIndex(of: existingType) else { continue }

            if viewTypeIndex < existingIndex {
                insertIndex = index
                break
            }
        }

        if insertIndex < orderedSubviews.count {
            insertSubview(view, at: insertIndex)
            orderedSubviews.insert(view, at: insertIndex)
        } else {
            addSubview(view)
            orderedSubviews.append(view)
        }

        print("[PlayerActionView] 添加视图: \(viewType.rawValue), 层级: \(insertIndex), 总数: \(orderedSubviews.count)")
    }

    /// 更新视图类型列表
    /// - Parameter list: 新的视图类型顺序
    public func updateViewTypeList(_ list: [PlayerViewType]) {
        viewTypeList = list
        reorderSubviews()
    }

    /// 移除指定类型的视图
    /// - Parameter viewType: 要移除的视图类型
    public func removeSubviews(ofType viewType: PlayerViewType) {
        for view in orderedSubviews.filter({ $0.playerViewType == viewType }) {
            view.removeFromSuperview()
        }
        orderedSubviews.removeAll { $0.playerViewType == viewType }
    }

    /// 获取指定类型的视图
    /// - Parameter viewType: 视图类型
    /// - Returns: 对应的视图
    public func view(for viewType: PlayerViewType) -> UIView? {
        return orderedSubviews.first { $0.playerViewType == viewType }
    }

    // MARK: - Private Methods

    private func reorderSubviews() {
        // 根据 viewTypeList 重新排序子视图
        let sortedSubviews = orderedSubviews.sorted { view1, view2 in
            guard let type1 = view1.playerViewType, let type2 = view2.playerViewType else {
                return false
            }
            guard let index1 = viewTypeList.firstIndex(of: type1),
                  let index2 = viewTypeList.firstIndex(of: type2) else {
                return false
            }
            return index1 < index2
        }

        // 重新排序
        for (index, view) in sortedSubviews.enumerated() {
            if view.superview === self {
                bringSubviewToFront(view)
            }
        }

        // 按照顺序重新添加
        for view in sortedSubviews {
            view.removeFromSuperview()
            addSubview(view)
        }

        orderedSubviews = sortedSubviews
    }

    // MARK: - Override

    public override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if let index = orderedSubviews.firstIndex(where: { $0 === subview }) {
            orderedSubviews.remove(at: index)
        }
    }
}
