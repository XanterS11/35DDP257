//
//  MainDJConsoleView.swift
//  35DDP257 - Pioneer Onyx Edition
//

import SwiftUI

struct MainDJConsoleView: View {
    @ObservedObject var audioEngine = AudioEngineManager.shared
    @ObservedObject var authVM: AuthViewModel
    
    @State private var showingLibraryModal = false
    @State private var showingAlbumLinkModal = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: Live Pioneer DJ Console
            djConsoleTab
                .tabItem {
                    Label("DJ Konsolu", systemImage: "opticaldisc.fill")
                }
                .tag(0)
            
            // Tab 2: Music Library
            LibraryTabView()
                .tabItem {
                    Label("Kütüphane", systemImage: "music.note.house.fill")
                }
                .tag(1)
            
            // Tab 3: Spotify Hub
            SpotifyBrowserView()
                .tabItem {
                    Label("Spotify", systemImage: "dot.radiowaves.left.and.right")
                }
                .tag(2)
        }
        .tint(Color(red: 0.0, green: 0.94, blue: 1.0))
        .sheet(isPresented: $showingLibraryModal) {
            LibraryModalView()
        }
        .sheet(isPresented: $showingAlbumLinkModal) {
            AlbumLinkImportView()
        }
    }
    
    // MARK: - DJ Console Screen
    private var djConsoleTab: some View {
        ZStack {
            Color(red: 0.02, green: 0.02, blue: 0.04)
                .ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Top Studio Master Bar
                    masterHeaderBar
                        .padding(.horizontal, 10)
                        .padding(.top, 4)
                    
                    // Deck A (Cyan)
                    DeckView(
                        deck: audioEngine.deckA,
                        onLoadTrackTapped: { showingLibraryModal = true },
                        onSyncBPMTapped: { syncDeckBPM(target: audioEngine.deckA, source: audioEngine.deckB) }
                    )
                    .padding(.horizontal, 8)
                    
                    // Center Pioneer Mixer & Crossfader
                    CrossfaderView(
                        position: $audioEngine.crossfaderPosition,
                        onAutoMix: { audioEngine.autoCrossfadeToNextDeck() }
                    )
                    .padding(.horizontal, 8)
                    
                    // Live Sound FX Launchpad (DJ / Pad / Club / Drum / User)
                    SoundboardLaunchpadView()
                        .padding(.horizontal, 8)
                    
                    // Scratch 2 (Magenta)
                    DeckView(
                        deck: audioEngine.deckB,
                        onLoadTrackTapped: { showingLibraryModal = true },
                        onSyncBPMTapped: { syncDeckBPM(target: audioEngine.deckB, source: audioEngine.deckA) }
                    )
                    .padding(.horizontal, 8)
                    .padding(.bottom, 28)
                }
            }
        }
    }
    
    // MARK: - Master Header Bar
    private var masterHeaderBar: some View {
        HStack(spacing: 12) {
            // Lock Console Button
            Button(action: { authVM.lockApp() }) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                    .padding(8)
                    .background(Color(red: 0.08, green: 0.09, blue: 0.14))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
            }
            
            // Brand Mark
            VStack(alignment: .leading, spacing: 1) {
                Text("PIONEER ONYX")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(2)
                Text("STUDIO MASTER LINKED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.55))
            }
            
            Spacer()
            
            // Master Volume
            HStack(spacing: 6) {
                Image(systemName: audioEngine.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 11))
                    .foregroundColor(audioEngine.isMuted ? DJColor.neonRed : Color(white: 0.7))
                    .onTapGesture { audioEngine.toggleMute() }
                
                Slider(value: $audioEngine.masterVolume, in: 0.0...1.0)
                    .tint(Color(red: 0.0, green: 0.94, blue: 1.0))
                    .frame(width: 75)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(red: 0.08, green: 0.09, blue: 0.14))
            .clipShape(Capsule())
            
            // Album Link Paste Button
            Button(action: { showingAlbumLinkModal = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("ALBÜM")
                }
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(red: 0.0, green: 0.94, blue: 1.0).opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(red: 0.0, green: 0.94, blue: 1.0).opacity(0.4), lineWidth: 1))
            }
            
            // Library Button
            Button(action: { showingLibraryModal = true }) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color(red: 0.0, green: 0.94, blue: 1.0))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(red: 0.06, green: 0.07, blue: 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }
    
    private func syncDeckBPM(target: DJDeck, source: DJDeck) {
        guard let sourceTrack = source.track else { return }
        let targetBase = target.track?.bpm ?? 120.0
        let sourceEffective = source.effectiveBPM
        
        let requiredMultiplier = sourceEffective / targetBase
        let requiredPercentage = (requiredMultiplier - 1.0) * 100.0
        target.setPitch(percentage: requiredPercentage)
    }
}
