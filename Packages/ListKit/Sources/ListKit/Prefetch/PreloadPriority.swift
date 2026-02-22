import Foundation

/**
 * 预加载优先级枚举
 */
public enum PreloadPriority: Int, Sendable, Comparable {
    /** 低优先级 */
    case low = 1
    /** 普通优先级 */
    case normal = 2
    /** 高优先级 */
    case high = 3
    /** 紧急优先级 */
    case urgent = 4

    /**
     * 比较两个优先级的先后顺序
     */
    public static func < (lhs: PreloadPriority, rhs: PreloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
