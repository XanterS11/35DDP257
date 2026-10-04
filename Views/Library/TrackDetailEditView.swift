//
//  TrackDetailEditView.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI

struct TrackDetailEditView: View {
    @ObservedObject var store = LocalMusicStore.shared
    var track: Track
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var artist: String = ""
    @State private var album: String = ""
    
    init(track: Track) {
        self.track = track
        _title = State(initialValue: track.title)
        _artist = State(initialValue: track.artist)
        _album = State(initialValue: track.album)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DJColor.darkBackground
                    .ignoresSafeArea()
                
                Form {
                    Section(header: Text("ŞARKI BİLGİLERİ").foregroundColor(DJColor.neonCyan)) {
                        TextField("Şarkı Adı", text: $title)
                        TextField("Sanatçı", text: $artist)
                        TextField("Albüm", text: $album)
                    }
                    .listRowBackground(DJColor.consoleSurface)
                    
                    Section(header: Text("TEKNİK DETAYLAR").foregroundColor(DJColor.textMuted)) {
                        HStack {
                            Text("Süre")
                            Spacer()
                            Text(track.formattedDuration)
                                .foregroundColor(DJColor.textSecondary)
                        }
                        HStack {
                            Text("BPM")
                            Spacer()
                            Text(String(format: "%.1f BPM", track.bpm))
                                .foregroundColor(DJColor.neonAmber)
                        }
                        HStack {
                            Text("Kaynak")
                            Spacer()
                            Text(track.isSpotify ? "Spotify" : "Yerel Ses Dosyası")
                                .foregroundColor(DJColor.textSecondary)
                        }
                    }
                    .listRowBackground(DJColor.consoleSurface)
                    
                    Section {
                        Button(role: .destructive, action: {
                            store.deleteTrack(id: track.id)
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Şarkıyı Kütüphaneden Sil")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(DJColor.consoleSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Şarkı Bilgisini Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                        .foregroundColor(DJColor.textSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        store.updateTrack(id: track.id, title: title, artist: artist, album: album)
                        dismiss()
                    }
                    .foregroundColor(DJColor.neonCyan)
                    .fontWeight(.bold)
                }
            }
        }
    }
}
