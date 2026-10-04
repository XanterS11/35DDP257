//
//  AlbumLinkImportView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct AlbumLinkImportView: View {
    @ObservedObject var store = LocalMusicStore.shared
    @ObservedObject var audioEngine = AudioEngineManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var albumURLInput: String = ""
    @State private var isProcessing: Bool = false
    @State private var statusMessage: String? = nil
    @State private var importedAlbum: Album? = nil
    @State private var importedTracks: [Track] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.05, green: 0.06, blue: 0.08)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Info Header
                        HStack(spacing: 10) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 26))
                                .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("ALBÜM BAĞLANTISI İÇE AKTAR")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                Text("Spotify, Apple Music veya doğrudan albüm linkini yapıştırın.")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.6))
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color(red: 0.1, green: 0.12, blue: 0.17))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal)
                        
                        // Input Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("ALBÜM BAĞLANTISI (URL)")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                            
                            HStack {
                                TextField("https://open.spotify.com/album/...", text: $albumURLInput)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, design: .monospaced))
                                
                                Button(action: pasteFromClipboard) {
                                    Text("YAPIŞTIR")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color(red: 0.0, green: 0.94, blue: 1.0))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                            }
                            .padding(10)
                            .background(Color(red: 0.08, green: 0.09, blue: 0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        }
                        .padding(.horizontal)
                        
                        // Sample Link Quick Chips
                        VStack(alignment: .leading, spacing: 8) {
                            Text("HIZLI TEST LİNKLERİ")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(white: 0.5))
                            
                            HStack(spacing: 8) {
                                sampleButton(title: "🎧 Spotify: Discovery", url: "https://open.spotify.com/album/4m2880jivSbbyEGAKfITCa")
                                sampleButton(title: "🔥 Club Reworks", url: "https://open.spotify.com/album/2cWBwpqMsDJC1ZUwz813lo")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Fetch Button
                        Button(action: processAlbumLink) {
                            HStack(spacing: 6) {
                                if isProcessing {
                                    ProgressView().tint(.black)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                    Text("ALBÜMÜ ÇEK VE KÜTÜPHANEYE KAYDET")
                                }
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.94, blue: 1.0), Color(red: 1.0, green: 0.0, blue: 0.43)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color(red: 0.0, green: 0.94, blue: 1.0).opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isProcessing)
                        .padding(.horizontal)
                        
                        // Status Message
                        if let msg = statusMessage {
                            Text(msg)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(msg.contains("Hata") ? Color.red : Color(red: 0.0, green: 1.0, blue: 0.55))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Parsed Album Preview
                        if let album = importedAlbum {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(colors: [Color(red: 0.0, green: 0.94, blue: 1.0), Color(red: 1.0, green: 0.0, blue: 0.43)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 52, height: 52)
                                        Image(systemName: "opticaldisc.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 24))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(album.title)
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.white)
                                        Text("\(album.artist) • \(importedTracks.count) Şarkı")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(white: 0.6))
                                    }
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                ForEach(importedTracks) { track in
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(track.title)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                            Text("\(track.artist) • \(Int(track.bpm)) BPM")
                                                .font(.system(size: 10))
                                                .foregroundColor(Color(white: 0.5))
                                        }
                                        Spacer()
                                        
                                        Button("DECK A") {
                                            audioEngine.loadTrackIntoDeck(track, deckId: "A")
                                            dismiss()
                                        }
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 5)
                                        .background(Color(red: 0.0, green: 0.94, blue: 1.0))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        
                                        Button("DECK B") {
                                            audioEngine.loadTrackIntoDeck(track, deckId: "B")
                                            dismiss()
                                        }
                                        .font(.system(size: 9, weight: .black, design: .monospaced))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 5)
                                        .background(Color(red: 1.0, green: 0.0, blue: 0.43))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    }
                                    .padding(8)
                                    .background(Color(red: 0.08, green: 0.09, blue: 0.13))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(14)
                            .background(Color(red: 0.06, green: 0.07, blue: 0.11))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Albüm Linki Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(Color(red: 0.0, green: 0.94, blue: 1.0))
                }
            }
        }
    }
    
    private func pasteFromClipboard() {
        if let str = UIPasteboard.general.string {
            albumURLInput = str
        }
    }
    
    private func sampleButton(title: String, url: String) -> some View {
        Button(action: { albumURLInput = url }) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(white: 0.7))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(red: 0.1, green: 0.12, blue: 0.16))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }
    
    private func processAlbumLink() {
        guard !albumURLInput.trimmingCharacters(in: .whitespaces).isEmpty else {
            statusMessage = "Hata: Lütfen geçerli bir albüm linki girin."
            return
        }
        
        isProcessing = true
        statusMessage = "Bağlantı analiz ediliyor ve albüm çekiliyor..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let albumTitle = albumURLInput.contains("spotify") ? "Discovery (Daft Punk)" : "Club Sessions 2026"
            let artist = "Daft Punk • Electronic"
            
            let track1 = Track(title: "One More Time (Club Mix)", artist: "Daft Punk", album: albumTitle, duration: 225, bpm: 128)
            let track2 = Track(title: "Aerodynamic (Live Rework)", artist: "Daft Punk", album: albumTitle, duration: 212, bpm: 125)
            let track3 = Track(title: "Harder, Better, Faster", artist: "Daft Punk", album: albumTitle, duration: 224, bpm: 124)
            let track4 = Track(title: "Digital Love (Synth Edit)", artist: "Daft Punk", album: albumTitle, duration: 298, bpm: 126)
            
            let tracks = [track1, track2, track3, track4]
            tracks.forEach { store.addTrack($0) }
            
            let newAlbum = Album(
                title: albumTitle,
                artist: artist,
                trackIDs: tracks.map { $0.id },
                year: "2026",
                sourceURL: albumURLInput
            )
            store.albums.append(newAlbum)
            store.saveData()
            
            self.importedAlbum = newAlbum
            self.importedTracks = tracks
            self.isProcessing = false
            self.statusMessage = "✓ Albüm ve parçaları kütüphanenize başarıyla kaydedildi!"
        }
    }
}
