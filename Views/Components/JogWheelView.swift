//
//  JogWheelView.swift
//  35DDP257 - Pioneer Onyx Edition
//

import SwiftUI

struct JogWheelView: View {
    @ObservedObject var deck: DJDeck
    var diameter: CGFloat = 175
    
    private let scratchProcessor = ScratchProcessor()
    @State private var isTouching: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            
            ZStack {
                // Platter Outer Bezel (Brushed Heavy Metal)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(red: 0.12, green: 0.14, blue: 0.19), Color(red: 0.04, green: 0.05, blue: 0.07)],
                            center: .center,
                            startRadius: diameter * 0.3,
                            endRadius: diameter * 0.5
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color(white: 0.3), Color(white: 0.1), Color(white: 0.25)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.9), radius: 14, x: 0, y: 8)
                
                // Photorealistic Vinyl Micro-Grooves
                ForEach(1..<6) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.035), lineWidth: 1)
                        .frame(width: diameter - CGFloat(i * 14), height: diameter - CGFloat(i * 14))
                }
                
                // Rotating Ring with Neon Marker
                ZStack {
                    Circle()
                        .stroke(deckColor.opacity(isTouching ? 0.8 : 0.25), lineWidth: 2)
                        .frame(width: diameter - 36, height: diameter - 36)
                    
                    // Specular Neon Position Needle
                    RoundedRectangle(cornerRadius: 2)
                        .fill(deckColor)
                        .frame(width: 4, height: 22)
                        .offset(y: -(diameter - 56) / 2)
                        .neonGlow(color: deckColor, radius: 8)
                }
                .rotationEffect(.degrees(deck.jogAngle))
                
                // Center LCD Screen Hub
                Circle()
                    .fill(Color(red: 0.03, green: 0.04, blue: 0.06))
                    .frame(width: diameter * 0.44, height: diameter * 0.44)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 1.5)
                    )
                    .overlay(
                        VStack(spacing: 2) {
                            Text(String(format: "%.1f", deck.effectiveBPM))
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundColor(Color.white)
                            
                            Text(deck.formattedCurrentTime)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(deckColor)
                            
                            Text(deck.id == "A" ? "DECK A" : "DECK B")
                                .font(.system(size: 7, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                        }
                    )
                    .shadow(color: Color.black.opacity(0.8), radius: 6, x: 0, y: 2)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isTouching {
                            isTouching = true
                            deck.isScratching = true
                            scratchProcessor.startTouch(at: value.location, center: center)
                        } else {
                            let result = scratchProcessor.processDrag(to: value.location, center: center)
                            deck.processScratch(deltaAngle: result.deltaAngle, scratchSpeed: result.scratchSpeed)
                        }
                    }
                    .onEnded { _ in
                        isTouching = false
                        deck.isScratching = false
                        scratchProcessor.endTouch()
                    }
            )
        }
        .frame(width: diameter, height: diameter)
    }
    
    private var deckColor: Color {
        deck.id == "A" ? Color(red: 0.0, green: 0.94, blue: 1.0) : Color(red: 1.0, green: 0.0, blue: 0.43)
    }
}
