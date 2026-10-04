//
//  DeckView.swift
//  35DDP257 - Pioneer Onyx Edition
//

import SwiftUI

struct DeckView: View {
    @ObservedObject var deck: DJDeck
    var onLoadTrackTapped: () -> Void
    var onSyncBPMTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Track Header & Live BPM
            HStack(spacing: 8) {
                // Scratch Badge
                Text(deck.id == "A" ? "SCRATCH 1" : "SCRATCH 2")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .neonGlow(color: accentColor, radius: 4)
                
                // Track Titles
                VStack(alignment: .leading, spacing: 1) {
                    Text(deck.track?.title ?? "Parça Yüklenmedi")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(deck.track?.artist ?? "Kütüphaneden şarkı seçin")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(white: 0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Live BPM
                Text(String(format: "%.1f", deck.effectiveBPM))
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(DJColor.neonAmber)
                
                // Load Button
                Button(action: onLoadTrackTapped) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(accentColor)
                        .padding(6)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.16))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 4)
            
            // Spectral Waveform
            WaveformView(deck: deck, height: 42)
            
            // Performance Stage (Pitch Fader + Jog Wheel + VU Meter)
            HStack(spacing: 6) {
                // Precision Tempo Fader
                VStack(spacing: 3) {
                    Text("+")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(Color(white: 0.4))
                    
                    Slider(
                        value: Binding(
                            get: { deck.pitchPercentage },
                            set: { deck.setPitch(percentage: $0) }
                        ),
                        in: -16.0...16.0
                    )
                    .tint(accentColor)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 85, height: 26)
                    
                    Text(String(format: "%+.1f%%", deck.pitchPercentage))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(deck.pitchPercentage == 0 ? Color(white: 0.4) : DJColor.neonAmber)
                    
                    Button("0.0") {
                        deck.resetPitch()
                    }
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(white: 0.6))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color(white: 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                }
                .frame(width: 36)
                
                Spacer()
                JogWheelView(deck: deck, diameter: 165)
                Spacer()
                
                // LED VU Meter
                VUMeterView(level: deck.vuLevel, height: 115, width: 8)
            }
            
            // Pioneer Silicone Performance Pads
            HStack(spacing: 6) {
                performancePad(title: "HOT CUE 1", sub: "INTRO") { deck.seek(to: 0) }
                performancePad(title: "HOT CUE 2", sub: "DROP") { deck.seek(to: deck.duration * 0.3) }
                performancePad(title: "LOOP 4", sub: "BEAT") { deck.toggleLoop() }
                performancePad(title: "FX ROLL", sub: "1/2") {}
            }
            
            // Pioneer Transport Controls
            HStack(spacing: 8) {
                // Round CUE Button
                Button(action: {}) {
                    Text("CUE")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(deck.isCuePressed ? .black : DJColor.neonAmber)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(deck.isCuePressed ? DJColor.neonAmber : Color(red: 0.12, green: 0.14, blue: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DJColor.neonAmber.opacity(0.5), lineWidth: 1.5)
                        )
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in if !deck.isCuePressed { deck.pressCue() } }
                        .onEnded { _ in deck.releaseCue() }
                )
                
                // Giant Round PLAY / PAUSE Button
                Button(action: { deck.togglePlayPause() }) {
                    HStack(spacing: 4) {
                        Image(systemName: deck.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .black))
                        Text(deck.isPlaying ? "DURDUR" : "ŞARKIYI BAŞLAT")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                    }
                    .foregroundColor(deck.isPlaying ? .black : accentColor)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(deck.isPlaying ? accentColor : Color(red: 0.12, green: 0.14, blue: 0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(accentColor.opacity(0.8), lineWidth: 1.5)
                    )
                    .neonGlow(color: deck.isPlaying ? accentColor : .clear, radius: 8)
                }
                
                // SYNC Button
                Button(action: onSyncBPMTapped) {
                    Text("SYNC")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 52, minHeight: 40)
                        .background(Color(red: 0.12, green: 0.14, blue: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.09, blue: 0.13), Color(red: 0.04, green: 0.05, blue: 0.07)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), accentColor.opacity(0.3), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
    }
    
    private var accentColor: Color {
        deck.id == "A" ? Color(red: 0.0, green: 0.94, blue: 1.0) : Color(red: 1.0, green: 0.0, blue: 0.43)
    }
    
    private func performancePad(title: String, sub: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(Color(white: 0.7))
                Text(sub)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .frame(maxWidth: .infinity, minHeight: 32)
            .background(Color(red: 0.11, green: 0.13, blue: 0.18))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
