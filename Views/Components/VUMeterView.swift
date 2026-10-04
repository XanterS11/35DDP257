//
//  VUMeterView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct VUMeterView: View {
    var level: Float // 0.0 to 1.0
    var segmentCount: Int = 10
    var height: CGFloat = 80
    var width: CGFloat = 10
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach((0..<segmentCount).reversed(), id: \.self) { index in
                let threshold = Float(index) / Float(segmentCount)
                let isActive = level >= threshold
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(segmentColor(for: index, isActive: isActive))
                    .frame(width: width, height: max(2, (height - CGFloat(segmentCount * 2)) / CGFloat(segmentCount)))
                    .opacity(isActive ? 1.0 : 0.2)
                    .neonGlow(color: isActive ? segmentColor(for: index, isActive: true) : Color.clear, radius: 2)
            }
        }
        .padding(3)
        .background(DJColor.platterDark)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(DJColor.panelBorder, lineWidth: 0.8)
        )
    }
    
    private func segmentColor(for index: Int, isActive: Bool) -> Color {
        if index >= 8 {
            return DJColor.neonRed
        } else if index >= 6 {
            return DJColor.neonAmber
        } else {
            return DJColor.neonGreen
        }
    }
}
