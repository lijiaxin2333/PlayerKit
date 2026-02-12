import Foundation

public enum PreloadPriority: Int, Sendable, Comparable {
    case low = 1
    case normal = 2
    case high = 3
    case urgent = 4

    public static func < (lhs: PreloadPriority, rhs: PreloadPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
