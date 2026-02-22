//
//  PlayerActionView.swift
//  playerkit
//

import UIKit
import Foundation

/** 播放器交互视图，根据 viewType 按预定义顺序管理子视图层级 */
@MainActor
public final class PlayerActionView: UIView, PlayerActionViewProtocol {

    /** 视图类型列表，定义层级顺序（index 越小层级越低） */
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
        .panelView,
        .debugView,
    ]

    /** 按层级排列的子视图列表 */
    private var orderedSubviews: [UIView] = []

    /** 使用 frame 初始化 */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    /** 使用 NSCoder 初始化 */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    /** 添加视图到指定层级类型，自动根据 viewTypeList 排列顺序 */
    public func addSubview(_ view: UIView, viewType: PlayerViewType) {

        if orderedSubviews.contains(where: { $0 === view }) {
            return
        }

        view.playerViewType = viewType

        guard let viewTypeIndex = viewTypeList.firstIndex(of: viewType) else {
            addSubview(view)
            orderedSubviews.append(view)
            return
        }

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

    /** 更新视图类型列表并重新排序子视图 */
    public func updateViewTypeList(_ list: [PlayerViewType]) {
        viewTypeList = list
        reorderSubviews()
    }

    /** 移除指定类型的所有视图 */
    public func removeSubviews(ofType viewType: PlayerViewType) {
        for view in orderedSubviews.filter({ $0.playerViewType == viewType }) {
            view.removeFromSuperview()
        }
        orderedSubviews.removeAll { $0.playerViewType == viewType }
    }

    /** 获取指定类型的视图 */
    public func view(for viewType: PlayerViewType) -> UIView? {
        return orderedSubviews.first { $0.playerViewType == viewType }
    }

    /** 根据 viewTypeList 重新排序所有子视图 */
    private func reorderSubviews() {
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

        for view in sortedSubviews {
            view.removeFromSuperview()
            addSubview(view)
        }

        orderedSubviews = sortedSubviews
    }

    /** 子视图即将被移除时，同步更新有序子视图列表 */
    public override func willRemoveSubview(_ subview: UIView) {
        super.willRemoveSubview(subview)
        if let index = orderedSubviews.firstIndex(where: { $0 === subview }) {
            orderedSubviews.remove(at: index)
        }
    }
}
