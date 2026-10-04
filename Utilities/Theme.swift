//
//  Theme.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

enum DJColor {
    // Backgrounds
    static let darkBackground = Color(red: 0.04, green: 0.05, blue: 0.08)       // #0B0D14
    static let consoleSurface = Color(red: 0.08, green: 0.09, blue: 0.13)       // #141721
    static let panelBorder = Color(red: 0.16, green: 0.18, blue: 0.25)          // #292E40
    static let platterDark = Color(red: 0.05, green: 0.06, blue: 0.09)          // #0D0F17

    // Neon Accents (Deck A: Cyan / Deck B: Magenta-Amber)
    static let neonCyan = Color(red: 0.0, green: 0.95, blue: 1.0)               // #00F2FF
    static let neonCyanDim = Color(red: 0.0, green: 0.6, blue: 0.7, opacity: 0.4)
    
    static let neonMagenta = Color(red: 1.0, green: 0.05, blue: 0.55)           // #FF0D8D
    static let neonAmber = Color(red: 1.0, green: 0.72, blue: 0.0)              // #FFB800
    static let neonGreen = Color(red: 0.05, green: 1.0, blue: 0.45)             // #0DFF73
    static let neonRed = Color(red: 1.0, green: 0.22, blue: 0.25)               // #FF3840

    // Text & Controls
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textMuted = Color(white: 0.4)
    static let metallicKnob = Color(red: 0.25, green: 0.27, blue: 0.32)
}

struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius / 2, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius, x: 0, y: 0)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 8) -> some View {
        self.modifier(NeonGlowModifier(color: color, radius: radius))
    }
    
    func djCardStyle() -> some View {
        self
            .background(DJColor.consoleSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(DJColor.panelBorder, lineWidth: 1)
            )
    }
}
