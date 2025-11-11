//
//  Extensions.swift
//  Orbitica Core
//
//  Utility extensions condivise per CGVector e CGPoint
//

import Foundation
import CoreGraphics

// MARK: - CGVector Extensions

extension CGVector {
    var length: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    func normalized() -> CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }
    
    func dot(_ other: CGVector) -> CGFloat {
        return dx * other.dx + dy * other.dy
    }
}

// MARK: - CGPoint Extensions

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return sqrt(dx * dx + dy * dy)
    }
    
    func angle(to other: CGPoint) -> CGFloat {
        let dx = other.x - x
        let dy = other.y - y
        return atan2(dy, dx)
    }
}
