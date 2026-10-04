//
//  CrossfaderView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct CrossfaderView: View {
    @Binding var position: Float // 0.0 to 1.0
    var onAutoMix: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Header Labels
            HStack {
                Text("DECK A")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(DJColor.neonCyan)
                
                Spacer()
                
                Button(action: onAutoMix) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.horizontal.fill")
                            .font(.system(size: 9))
                        Text("AUTO MIX")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(DJColor.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DJColor.panelBorder)
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                Text("DECK B")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(DJColor.neonMagenta)
            }
            .padding(.horizontal, 8)
            
            // Crossfader Rail
            GeometryReader { geo in
                let thumbWidth: CGFloat = 36
                let trackWidth = geo.size.width - thumbWidth
                let thumbX = CGFloat(position) * trackWidth
                
                ZStack(alignment: .leading) {
                    // Track Channel
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DJColor.platterDark)
                        .frame(height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(DJColor.panelBorder, lineWidth: 1)
                        )
                    
                    // Center Notch Line
                    Rectangle()
                        .fill(DJColor.textMuted)
                        .frame(width: 2, height: 16)
                        .position(x: geo.size.width / 2, y: 12)
                    
                    // Active Blend Gradient
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(DJColor.neonCyan.opacity(Double(1.0 - position) * 0.4))
                        Rectangle()
                            .fill(DJColor.neonMagenta.opacity(Double(position) * 0.4))
                    }
                    .frame(height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .padding(.horizontal, 2)
                    
                    // Slider Knob / Thumb
                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.35), Color(white: 0.18)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: thumbWidth, height: 32)
                        .overlay(
                            VStack(spacing: 2) {
                                Rectangle().fill(Color.white.opacity(0.8)).frame(width: 2, height: 18)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(faderKnobBorderColor, lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.6), radius: 4, x: 0, y: 2)
                        .offset(x: thumbX)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { val in
                                    let newPos = Float(val.location.x / trackWidth)
                                    position = max(0.0, min(1.0, newPos))
                                }
                        )
                }
                .frame(height: 32)
            }
            .frame(height: 32)
            
            // Value Readout
            HStack {
                Text("\(Int((1.0 - position) * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(DJColor.neonCyan)
                Spacer()
                Text("CROSSFADER")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(DJColor.textMuted)
                Spacer()
                Text("\(Int(position * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(DJColor.neonMagenta)
            }
            .padding(.horizontal, 8)
        }
        .padding(10)
        .djCardStyle()
    }
    
    private var faderKnobBorderColor: Color {
        if position < 0.45 {
            return DJColor.neonCyan
        } else if position > 0.55 {
            return DJColor.neonMagenta
        } else {
            return Color.white
        }
    }
}
