//
//  LibraryModalView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct LibraryModalView: View {
    @ObservedObject var store = LocalMusicStore.shared
    @ObservedObject var audioEngine = AudioEngineManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var showingFilePicker = false
    @State private var selectedTab = 0 // 0: Tracks, 1: Playlists, 2: Albums
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Custom Tab Switcher
                    HStack(spacing: 8) {
                        tabButton(title: "ŞARKILAR (\(store.tracks.count))", index: 0)
                        tabButton(title: "PLAYLİSTLER (\(store.playlists.count))", index: 1)
                        tabButton(title: "ALBÜMLER (\(store.albums.count))", index: 2)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DJColor.textMuted)
                        TextField("Şarkı, sanatçı veya albüm ara...", text: $searchText)
                            .foregroundColor(DJColor.textPrimary)
                    }
                    .padding(10)
                    .background(DJColor.consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    
                    // List Content
                    if selectedTab == 0 {
                        trackListView
                    } else if selectedTab == 1 {
                        playlistListView
                    } else {
                        albumListView
                    }
                }
            }
            .navigationTitle("Müzik Kütüphanesi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingFilePicker = true }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                            Text("Müzik Ekle")
                        }
                        .foregroundColor(DJColor.neonGreen)
                        .font(.system(size: 13, weight: .bold))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(DJColor.neonCyan)
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPickerView { url in
                    Task {
                        _ = await MusicFileManager.shared.importAudioFile(from: url)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(selectedTab == index ? Color.black : DJColor.textSecondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(selectedTab == index ? DJColor.neonCyan : DJColor.consoleSurface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private var filteredTracks: [Track] {
        if searchText.isEmpty { return store.tracks }
        return store.tracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText) ||
            $0.album.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var trackListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(filteredTracks) { track in
                    HStack(spacing: 12) {
                        // Artwork or Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(DJColor.platterDark)
                                .frame(width: 44, height: 44)
                            
                            if let art = store.artworkForTrack(track) {
                                Image(uiImage: art)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            } else {
                                Image(systemName: "music.note")
                                    .foregroundColor(DJColor.textMuted)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(track.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(DJColor.textPrimary)
                                .lineLimit(1)
                            
                            Text("\(track.artist) • \(track.album)")
                                .font(.system(size: 11))
                                .foregroundColor(DJColor.textSecondary)
                                .lineLimit(1)
                            
                            HStack(spacing: 8) {
                                Text("\(Int(track.bpm)) BPM")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(DJColor.neonAmber)
                                Text(track.formattedDuration)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(DJColor.textMuted)
                            }
                        }
                        
                        Spacer()
                        
                        // Load Buttons
                        HStack(spacing: 6) {
                            Button(action: {
                                audioEngine.loadTrackIntoDeck(track, deckId: "A")
                                dismiss()
                            }) {
                                Text("DECK A")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(Color.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(DJColor.neonCyan)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Button(action: {
                                audioEngine.loadTrackIntoDeck(track, deckId: "B")
                                dismiss()
                            }) {
                                Text("DECK B")
                                    .font(.system(size: 10, weight: .black, design: .monospaced))
                                    .foregroundColor(Color.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .background(DJColor.neonMagenta)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                    .padding(10)
                    .background(DJColor.consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var playlistListView: some View {
        List {
            ForEach(store.playlists) { pl in
                VStack(alignment: .leading, spacing: 4) {
                    Text(pl.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DJColor.textPrimary)
                    Text("\(pl.trackIDs.count) Şarkı")
                        .font(.system(size: 12))
                        .foregroundColor(DJColor.textSecondary)
                }
                .listRowBackground(DJColor.consoleSurface)
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private var albumListView: some View {
        List {
            ForEach(store.albums) { alb in
                VStack(alignment: .leading, spacing: 4) {
                    Text(alb.title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(DJColor.textPrimary)
                    Text("\(alb.artist) • \(alb.trackIDs.count) Şarkı")
                        .font(.system(size: 12))
                        .foregroundColor(DJColor.textSecondary)
                }
                .listRowBackground(DJColor.consoleSurface)
            }
        }
        .scrollContentBackground(.hidden)
    }
}
