//
//  ScratchProcessor.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import CoreGraphics

final class ScratchProcessor {
    private var lastAngle: Double = 0
    private var lastTimestamp: TimeInterval = 0
    private(set) var currentVelocity: Double = 0
    
    // Smooth factor for scratch realism
    private let smoothingFactor: Double = 0.25
    
    func startTouch(at point: CGPoint, center: CGPoint) {
        lastAngle = calculateAngle(from: center, to: point)
        lastTimestamp = Date().timeIntervalSince1970
        currentVelocity = 0
    }
    
    func processDrag(to point: CGPoint, center: CGPoint) -> (deltaAngle: Double, scratchSpeed: Float) {
        let currentAngle = calculateAngle(from: center, to: point)
        let now = Date().timeIntervalSince1970
        let timeDelta = max(0.005, now - lastTimestamp)
        
        var diff = currentAngle - lastAngle
        // Normalize wrap-around (-180 to 180 degrees)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        
        // Angular velocity (degrees per second)
        let rawVelocity = diff / timeDelta
        currentVelocity = (rawVelocity * smoothingFactor) + (currentVelocity * (1.0 - smoothingFactor))
        
        lastAngle = currentAngle
        lastTimestamp = now
        
        // Translate angular velocity to playback rate multiplier (-3.0x to +3.0x)
        let rateMultiplier = Float(currentVelocity / 180.0) // 180 deg/s is roughly 1.0x normal speed
        let clampedRate = max(-4.0, min(4.0, rateMultiplier))
        
        return (deltaAngle: diff, scratchSpeed: clampedRate)
    }
    
    func endTouch() {
        currentVelocity = 0
    }
    
    private func calculateAngle(from center: CGPoint, to point: CGPoint) -> Double {
        let radians = atan2(point.y - center.y, point.x - center.x)
        var degrees = radians * 180.0 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }
}
