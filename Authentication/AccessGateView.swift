//
//  AccessGateView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct AccessGateView: View {
    @ObservedObject var authVM: AuthViewModel
    
    let keypadLayout: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["clr", "0", "del"]
    ]
    
    var body: some View {
        ZStack {
            DJColor.darkBackground
                .ignoresSafeArea()
            
            // Background ambient glow
            RadialGradient(
                gradient: Gradient(colors: [DJColor.neonCyan.opacity(0.12), Color.clear]),
                center: .top,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer(minLength: 20)
                
                // Header Logo & DJ Badge
                VStack(spacing: 8) {
                    Image(systemName: "opticaldisc.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [DJColor.neonCyan, DJColor.neonMagenta],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .neonGlow(color: DJColor.neonCyan, radius: 14)
                    
                    Text("DJ CONSOLE")
                        .font(.system(size: 26, weight: .black, design: .monospaced))
                        .foregroundColor(DJColor.textPrimary)
                        .tracking(4)
                    
                    Text(authHeaderSubtitle)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(DJColor.neonCyan)
                        .tracking(1.5)
                }
                
                // PIN Dots (5 Digits - 35257)
                HStack(spacing: 16) {
                    ForEach(0..<5, id: \.self) { index in
                        ZStack {
                            Circle()
                                .stroke(DJColor.panelBorder, lineWidth: 2)
                                .frame(width: 20, height: 20)
                            
                            if index < authVM.enteredPin.count {
                                Circle()
                                    .fill(DJColor.neonCyan)
                                    .frame(width: 14, height: 14)
                                    .neonGlow(color: DJColor.neonCyan, radius: 8)
                            }
                        }
                    }
                }
                .padding(.vertical, 12)
                
                // Error / Lockout Banner
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(DJColor.neonRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                } else {
                    Text("GÜVENLİ ERİŞİM İÇİN 6 HANELİ ŞİFRE GİRİN")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(DJColor.textMuted)
                }
                
                Spacer(minLength: 10)
                
                // Keypad Matrix
                VStack(spacing: 16) {
                    ForEach(keypadLayout, id: \.self) { row in
                        HStack(spacing: 24) {
                            ForEach(row, id: \.self) { key in
                                KeypadButton(
                                    key: key,
                                    isDisabled: authVM.isLockedOut,
                                    action: { handleKeypadPress(key) }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer(minLength: 30)
            }
        }
    }
    
    private var authHeaderSubtitle: String {
        if authVM.isInitialSetup {
            return authVM.isConfirmingSetup ? "ŞİFREYİ ONAYLAYIN" : "YENİ DJ ŞİFRESİ BELİRLEYİN"
        } else {
            return "ENTER DJ ACCESS CODE"
        }
    }
    
    private func handleKeypadPress(_ key: String) {
        switch key {
        case "del":
            authVM.deleteDigit()
        case "clr":
            authVM.enteredPin = ""
        default:
            authVM.appendDigit(key)
        }
    }
}

// MARK: - Keypad Button Component
struct KeypadButton: View {
    let key: String
    var isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(DJColor.consoleSurface)
                    .overlay(
                        Circle()
                            .stroke(DJColor.panelBorder, lineWidth: 1.5)
                    )
                    .frame(width: 76, height: 76)
                
                buttonContent
            }
        }
        .buttonStyle(KeypadPressStyle())
        .disabled(isDisabled && key != "clr")
        .opacity(isDisabled ? 0.4 : 1.0)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        if key == "del" {
            Image(systemName: "delete.backward")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(DJColor.textSecondary)
        } else if key == "clr" {
            Text("C")
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(DJColor.textSecondary)
        } else {
            Text(key)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .foregroundColor(DJColor.textPrimary)
        }
    }
}

struct KeypadPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
