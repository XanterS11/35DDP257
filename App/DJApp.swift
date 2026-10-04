//
//  DJApp.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

@main
struct DJApp: App {
    @StateObject private var authVM = AuthViewModel()
    @State private var isShowingSplash: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        AudioSessionConfigurator.shared.configureSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                if isShowingSplash {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isShowingSplash = false
                        }
                    }
                    .transition(.opacity)
                } else if authVM.isUnlocked {
                    MainDJConsoleView(authVM: authVM)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    AccessGateView(authVM: authVM)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: authVM.isUnlocked)
            .animation(.easeInOut(duration: 0.4), value: isShowingSplash)
            .preferredColorScheme(.dark)
            .onOpenURL { url in
                // Handle Spotify OAuth Callback
                if url.scheme == "antigravity-dj" {
                    Task {
                        await SpotifyAuthManager.shared.handleCallback(url: url)
                    }
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                authVM.handleAppMovedToBackground()
            }
        }
    }
}
