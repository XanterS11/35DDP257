//
//  SoundboardLaunchpadView.swift
//  35DDP257 - DJ Pro Console
//

import SwiftUI
import AVFoundation

struct SoundboardLaunchpadView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("🔊 CANLI DJ SES EFEKTLERİ")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)
                Spacer()
                Text("REAL-TIME READY")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.55))
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 10) {
                fxButton(icon: "🚨", title: "AIRHORN", sub: "1.75s Drop", color: Color(red: 1.0, green: 0.2, blue: 0.1)) {
                    playSoundFile(name: "airhorn", offset: 1.75)
                }
                fxButton(icon: "👑", title: "DJ BURAK", sub: "Özel Drop", color: Color(red: 0.0, green: 0.94, blue: 1.0)) {
                    playSoundFile(name: "djburak", offset: 0.0)
                }
                fxButton(icon: "🔥", title: "GIVE ME", sub: "To Music", color: Color(red: 1.0, green: 0.05, blue: 0.45)) {
                    playSoundFile(name: "givemetomusic", offset: 0.0)
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color(red: 0.09, green: 0.11, blue: 0.16), Color(red: 0.05, green: 0.06, blue: 0.09)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func fxButton(icon: String, title: String, sub: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(icon).font(.system(size: 22))
                Text(title)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(sub)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(white: 0.75))
            }
            .frame(maxWidth: .infinity, minHeight: 65)
            .background(Color(red: 0.12, green: 0.15, blue: 0.22))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.5), lineWidth: 1.5)
            )
        }
    }
    
    private func playSoundFile(name: String, offset: Double = 0.0) {
        AudioServicesPlaySystemSound(1104) // Haptic feedback
        if let soundURL = Bundle.main.url(forResource: name, withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: soundURL)
                if offset > 0 {
                    player.currentTime = offset
                }
                player.play()
            } catch {
                var soundID: SystemSoundID = 0
                AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
                AudioServicesPlaySystemSound(soundID)
            }
        }
    }
}
