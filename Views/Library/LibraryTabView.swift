//
//  LibraryTabView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct LibraryTabView: View {
    @ObservedObject var store = LocalMusicStore.shared
    @ObservedObject var audioEngine = AudioEngineManager.shared
    
    @State private var showingFilePicker = false
    @State private var showingCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var editingTrack: Track? = nil
    @State private var selectedSegment = 0 // 0: Tracks, 1: Playlists, 2: Albums
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 12) {
                    // Segment Picker
                    Picker("Kategori", selection: $selectedSegment) {
                        Text("Şarkılar (\(store.tracks.count))").tag(0)
                        Text("Playlistler (\(store.playlists.count))").tag(1)
                        Text("Albümler (\(store.albums.count))").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(DJColor.textMuted)
                        TextField("Kütüphanede ara...", text: $searchText)
                            .foregroundColor(DJColor.textPrimary)
                    }
                    .padding(10)
                    .background(DJColor.consoleSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                    
                    // Content
                    if selectedSegment == 0 {
                        tracksListView
                    } else if selectedSegment == 1 {
                        playlistsListView
                    } else {
                        albumsListView
                    }
                }
            }
            .navigationTitle("Müzik Kütüphanesi")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingFilePicker = true }) {
                            Label("Ses Dosyası İçe Aktar", systemImage: "doc.badge.plus")
                        }
                        Button(action: { showingCreatePlaylist = true }) {
                            Label("Yeni Playlist Oluştur", systemImage: "music.note.list")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DJColor.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showingFilePicker) {
                DocumentPickerView { url in
                    Task {
                        _ = await MusicFileManager.shared.importAudioFile(from: url)
                    }
                }
            }
            .sheet(item: $editingTrack) { track in
                TrackDetailEditView(track: track)
            }
            .alert("Yeni Playlist", isPresented: $showingCreatePlaylist) {
                TextField("Playlist Adı", text: $newPlaylistName)
                Button("İptal", role: .cancel) { newPlaylistName = "" }
                Button("Oluştur") {
                    if !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty {
                        _ = store.createPlaylist(name: newPlaylistName)
                        newPlaylistName = ""
                    }
                }
            }
        }
    }
    
    private var filteredTracks: [Track] {
        if searchText.isEmpty { return store.tracks }
        return store.tracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var tracksListView: some View {
        List {
            ForEach(filteredTracks) { track in
                HStack(spacing: 12) {
                    // Artwork / Icon
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
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(DJColor.textPrimary)
                        Text("\(track.artist) • \(track.album)")
                            .font(.system(size: 11))
                            .foregroundColor(DJColor.textSecondary)
                        HStack(spacing: 6) {
                            Text(String(format: "%.1f BPM", track.bpm))
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(DJColor.neonAmber)
                            Text("•")
                                .foregroundColor(DJColor.textMuted)
                            Text(track.formattedDuration)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(DJColor.textMuted)
                        }
                    }
                    
                    Spacer()
                    
                    // Deck Buttons
                    Button("DECK A") {
                        audioEngine.loadTrackIntoDeck(track, deckId: "A")
                    }
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(DJColor.neonCyan)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    
                    Button("DECK B") {
                        audioEngine.loadTrackIntoDeck(track, deckId: "B")
                    }
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(Color.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 5)
                    .background(DJColor.neonMagenta)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    editingTrack = track
                }
                .listRowBackground(DJColor.consoleSurface)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let track = filteredTracks[index]
                    store.deleteTrack(id: track.id)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private var playlistsListView: some View {
        List {
            ForEach(store.playlists) { pl in
                VStack(alignment: .leading, spacing: 4) {
                    Text(pl.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(DJColor.textPrimary)
                    Text("\(pl.trackIDs.count) Şarkı")
                        .font(.system(size: 12))
                        .foregroundColor(DJColor.neonCyan)
                }
                .listRowBackground(DJColor.consoleSurface)
            }
            .onDelete { indexSet in
                for idx in indexSet {
                    store.deletePlaylist(id: store.playlists[idx].id)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private var albumsListView: some View {
        List {
            ForEach(store.albums) { alb in
                VStack(alignment: .leading, spacing: 4) {
                    Text(alb.title)
                        .font(.system(size: 16, weight: .bold))
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
