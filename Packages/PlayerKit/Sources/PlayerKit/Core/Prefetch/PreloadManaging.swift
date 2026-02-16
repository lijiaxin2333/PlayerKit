import Foundation

/**
 * 预加载状态枚举
 */
public enum PreloadStatus: Sendable, Equatable {
    /** 空闲 */
    case idle
    /** 已排队 */
    case queued
    /** 运行中，携带已加载进度 */
    case running(progress: Int64)
    /** 已完成 */
    case completed
    /** 失败，携带错误描述 */
    case failed(String)
}

/**
 * 预加载管理协议，定义预加载管理器接口
 */
public protocol PreloadManaging: Sendable {
    /**
     * 更新预加载窗口
     */
    func updateWindow(urlsInOrder: [URL], focusIndex: Int) async
    /**
     * 预加载指定 URL
     */
    func preload(url: URL, priority: PreloadPriority) async
    /**
     * 取消指定 URL 的预加载
     */
    func cancel(url: URL) async
    /**
     * 取消所有预加载
     */
    func cancelAll() async
    /**
     * 获取指定 URL 的预加载状态
     */
    func status(of url: URL) async -> PreloadStatus
}
