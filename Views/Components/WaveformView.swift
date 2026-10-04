//
//  WaveformView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct WaveformView: View {
    @ObservedObject var deck: DJDeck
    var height: CGFloat = 46
    
    var body: some View {
        GeometryReader { geo in
            let samples = deck.track?.waveformSamples ?? defaultSamples
            let barWidth: CGFloat = 2.5
            let spacing: CGFloat = 1.5
            let totalBars = samples.count
            let availableWidth = geo.size.width
            let step = availableWidth / CGFloat(max(1, totalBars))
            
            ZStack(alignment: .leading) {
                // Waveform Bars
                HStack(alignment: .center, spacing: spacing) {
                    ForEach(0..<totalBars, id: \.self) { index in
                        let sample = CGFloat(samples[index])
                        let barHeight = max(4, sample * (height - 8))
                        let progressThreshold = Double(index) / Double(totalBars)
                        let isPlayed = progressThreshold <= deck.playbackProgress
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(isPlayed ? deckColor : DJColor.panelBorder)
                            .frame(width: max(1.5, step - spacing), height: barHeight)
                            .opacity(isPlayed ? 0.95 : 0.4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Playhead Needle
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: height)
                    .neonGlow(color: Color.white, radius: 4)
                    .offset(x: max(0, min(geo.size.width - 2, CGFloat(deck.playbackProgress) * geo.size.width)))
            }
            .background(DJColor.platterDark.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(DJColor.panelBorder.opacity(0.8), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let progress = Double(val.location.x / geo.size.width)
                        deck.seekByProgress(progress)
                    }
            )
        }
        .frame(height: height)
    }
    
    private var deckColor: Color {
        deck.id == "A" ? DJColor.neonCyan : DJColor.neonMagenta
    }
    
    private var defaultSamples: [Float] {
        (0..<60).map { i in
            Float(sin(Double(i) * 0.3) * 0.3 + 0.5)
        }
    }
}
