//
//  SplashScreenView.swift
//  35DDP257 - BMW Welcome Experience
//

import SwiftUI

struct SplashScreenView: View {
    var onFinish: () -> Void
    
    @State private var logoRotation: Double = 0
    @State private var logoScale: CGFloat = 0.7
    @State private var opacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var glowOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.04, blue: 0.06)
                .ignoresSafeArea()
            
            // Radial Ambient Glow
            RadialGradient(
                colors: [Color(red: 0.0, green: 0.45, blue: 0.9).opacity(glowOpacity), Color.clear],
                center: .center,
                startRadius: 40,
                endRadius: 320
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // BMW Rotating Emblem
                BMWLogoView()
                    .frame(width: 140, height: 140)
                    .rotation3DEffect(.degrees(logoRotation), axis: (x: 0, y: 1, z: 0))
                    .scaleEffect(logoScale)
                    .shadow(color: Color(red: 0.0, green: 0.6, blue: 1.0).opacity(0.5), radius: 25, x: 0, y: 10)
                
                // License Plate & Welcome Text
                VStack(spacing: 8) {
                    Text("35 DDP 257")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(4)
                        .shadow(color: Color(red: 0.0, green: 0.6, blue: 1.0).opacity(0.8), radius: 10, x: 0, y: 0)
                    
                    Text("Aracınıza Hoş Geldiniz")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(white: 0.8))
                        .tracking(1.5)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(red: 0.0, green: 1.0, blue: 0.5))
                            .frame(width: 6, height: 6)
                        Text("DJ SİSTEMİ BAŞLATILIYOR")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                            .tracking(2)
                    }
                    .padding(.top, 10)
                }
                .offset(y: textOffset)
                .opacity(opacity)
                
                Spacer()
            }
        }
        .onAppear {
            // Animation sequence
            withAnimation(.easeOut(duration: 1.2)) {
                opacity = 1.0
                logoScale = 1.0
                textOffset = 0
                glowOpacity = 0.35
            }
            
            // BMW 3D Spin
            withAnimation(.easeInOut(duration: 2.2)) {
                logoRotation = 720 // 2 full 3D spins
            }
            
            // Finish after 3.2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    opacity = 0
                    logoScale = 1.15
                    glowOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    onFinish()
                }
            }
        }
    }
}

// Custom BMW Emblem (uses uploaded bmw.png image with fallback)
struct BMWLogoView: View {
    var body: some View {
        Group {
            if let img = UIImage(named: "bmw") ?? UIImage(contentsOfFile: "bmw.png") {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .shadow(color: Color(red: 0.0, green: 0.45, blue: 0.9).opacity(0.6), radius: 20)
            } else {
                vectorEmblem
            }
        }
    }
    
    private var vectorEmblem: some View {
        ZStack {
            // Chrome Outer Bezel
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.85), Color(white: 0.2), Color(white: 0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
            
            // Black Outer Ring with BMW Text
            Circle()
                .fill(Color(red: 0.07, green: 0.08, blue: 0.1))
                .frame(width: 130, height: 130)
                .overlay(
                    VStack {
                        Text("B  M  W")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .tracking(6)
                            .padding(.top, 8)
                        Spacer()
                    }
                )
            
            // Inner Chrome Ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color(white: 0.9), Color(white: 0.3), Color(white: 0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 86, height: 86)
            
            // Bavarian Quadrants (Blue & White)
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 82, height: 82)
                
                // Top-Left Blue
                QuadrantShape(startAngle: .degrees(180), endAngle: .degrees(270))
                    .fill(Color(red: 0.0, green: 0.42, blue: 0.82))
                    .frame(width: 82, height: 82)
                
                // Bottom-Right Blue
                QuadrantShape(startAngle: .degrees(0), endAngle: .degrees(90))
                    .fill(Color(red: 0.0, green: 0.42, blue: 0.82))
                    .frame(width: 82, height: 82)
            }
            .clipShape(Circle())
        }
    }
}

struct QuadrantShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}
