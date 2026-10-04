//
//  SpotifyBrowserView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct SpotifyBrowserView: View {
    @ObservedObject var auth = SpotifyAuthManager.shared
    @ObservedObject var remote = SpotifyRemoteController.shared
    
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var selectedPlaylist: SpotifyPlaylist? = nil
    @State private var playlistTracks: [SpotifyTrack] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Spotify Policy Banner (Clear explanation of Hybrid DJ architecture)
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(DJColor.neonAmber)
                            .font(.system(size: 20))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HİBRİT MİMARİ BİLGİLENDİRMESİ")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(DJColor.neonAmber)
                            Text("Spotify API ve DRM kuralları gereği Spotify ses akışına ham erişim sağlanamaz ve scratch uygulanamaz. Tam scratch ve çift deck DJ miksajı için 'Kütüphane' sekmesinden kendi ses dosyalarınızı (MP3/WAV/M4A) kullanabilirsiniz.")
                                .font(.system(size: 10))
                                .foregroundColor(DJColor.textSecondary)
                        }
                    }
                    .padding(10)
                    .background(DJColor.consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DJColor.neonAmber.opacity(0.4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    if !auth.isAuthenticated {
                        unauthenticatedView
                    } else {
                        authenticatedContentView
                    }
                    
                    // Now Playing Bar for Spotify Remote
                    if auth.isAuthenticated && !remote.currentTrackTitle.isEmpty {
                        spotifyRemoteBar
                    }
                }
            }
            .navigationTitle("Spotify Hub")
            .toolbar {
                if auth.isAuthenticated {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Çıkış Yap") {
                            auth.signOut()
                            playlists = []
                        }
                        .foregroundColor(DJColor.neonRed)
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
            }
        }
    }
    
    // MARK: - Unauthenticated View
    private var unauthenticatedView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 64))
                .foregroundColor(DJColor.neonGreen)
                .neonGlow(color: DJColor.neonGreen, radius: 10)
            
            Text("SPOTIFY ENTEGRASYONU")
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundColor(DJColor.textPrimary)
            
            Text("Spotify hesabınızı bağlayarak çalma listelerinizi, albümlerinizi ve şarkı BPM değerlerinizi görüntüleyin.")
                .font(.system(size: 13))
                .foregroundColor(DJColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            if let err = auth.authError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(DJColor.neonRed)
                    .padding(.horizontal)
            }
            
            Button(action: {
                auth.startOAuthFlow()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("SPOTIFY İLE BAĞLAN")
                }
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundColor(Color.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(DJColor.neonGreen)
                .clipShape(Capsule())
                .neonGlow(color: DJColor.neonGreen, radius: 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Authenticated Content
    private var authenticatedContentView: some View {
        VStack(spacing: 8) {
            if isLoading {
                ProgressView("Spotify verileri alınıyor...")
                    .foregroundColor(DJColor.textPrimary)
                    .padding()
            } else {
                List {
                    Section(header: Text("ÇALMA LİSTELERİNİZ").foregroundColor(DJColor.neonCyan)) {
                        ForEach(playlists) { pl in
                            Button(action: {
                                Task { await loadTracksForPlaylist(pl) }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "music.note.list")
                                        .foregroundColor(DJColor.neonGreen)
                                        .font(.system(size: 20))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(pl.name)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(DJColor.textPrimary)
                                        Text("\(pl.tracks?.total ?? 0) Şarkı")
                                            .font(.system(size: 11))
                                            .foregroundColor(DJColor.textSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(DJColor.textMuted)
                                }
                            }
                            .listRowBackground(DJColor.consoleSurface)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .onAppear {
            Task { await loadUserPlaylists() }
        }
        .sheet(item: $selectedPlaylist) { playlist in
            playlistDetailModal(playlist: playlist)
        }
    }
    
    private func loadUserPlaylists() async {
        isLoading = true
        do {
            playlists = try await SpotifyAPIService.shared.fetchUserPlaylists()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    private func loadTracksForPlaylist(_ playlist: SpotifyPlaylist) async {
        selectedPlaylist = playlist
        do {
            playlistTracks = try await SpotifyAPIService.shared.fetchPlaylistTracks(playlistID: playlist.id)
        } catch {
            playlistTracks = []
        }
    }
    
    // MARK: - Playlist Detail Modal
    private func playlistDetailModal(playlist: SpotifyPlaylist) -> some View {
        NavigationView {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                List {
                    ForEach(playlistTracks) { track in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(DJColor.textPrimary)
                                Text(track.artistNames)
                                    .font(.system(size: 11))
                                    .foregroundColor(DJColor.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await remote.playTrack(uri: track.uri)
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "play.fill")
                                    Text("ÇAL")
                                }
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(Color.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(DJColor.neonGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        .listRowBackground(DJColor.consoleSurface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { selectedPlaylist = nil }
                        .foregroundColor(DJColor.neonCyan)
                }
            }
        }
    }
    
    // MARK: - Spotify Remote Player Bar
    private var spotifyRemoteBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .foregroundColor(DJColor.neonGreen)
                .font(.system(size: 28))
                .neonGlow(color: DJColor.neonGreen, radius: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(remote.currentTrackTitle)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(DJColor.textPrimary)
                    .lineLimit(1)
                Text(remote.currentArtist)
                    .font(.system(size: 11))
                    .foregroundColor(DJColor.textSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    if remote.isPlaying {
                        await remote.pause()
                    } else {
                        await remote.resume()
                    }
                }
            }) {
                Image(systemName: remote.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(DJColor.neonGreen)
            }
            
            Button(action: {
                Task { await remote.skipNext() }
            }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 18))
                    .foregroundColor(DJColor.textPrimary)
            }
        }
        .padding(12)
        .background(DJColor.consoleSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}
