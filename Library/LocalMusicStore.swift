//
//  LocalMusicStore.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import Combine
import UIKit

@MainActor
final class LocalMusicStore: ObservableObject {
    static let shared = LocalMusicStore()
    
    @Published var tracks: [Track] = []
    @Published var playlists: [Playlist] = []
    @Published var albums: [Album] = []
    
    private let tracksFile = "dj_tracks_db.json"
    private let playlistsFile = "dj_playlists_db.json"
    private let albumsFile = "dj_albums_db.json"
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    var audioStorageDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("DJTracks", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    var artworkStorageDirectory: URL {
        let dir = documentsDirectory.appendingPathComponent("DJArtwork", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    init() {
        loadData()
        if tracks.isEmpty {
            preloadSampleDemoTracks()
        }
    }
    
    // MARK: - Persistence
    func loadData() {
        tracks = loadJSON(filename: tracksFile) ?? []
        playlists = loadJSON(filename: playlistsFile) ?? []
        albums = loadJSON(filename: albumsFile) ?? []
    }
    
    func saveData() {
        saveJSON(tracks, filename: tracksFile)
        saveJSON(playlists, filename: playlistsFile)
        saveJSON(albums, filename: albumsFile)
    }
    
    private func saveJSON<T: Encodable>(_ object: T, filename: String) {
        let url = documentsDirectory.appendingPathComponent(filename)
        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: url, options: [.atomicWrite])
        } catch {
            print("[LocalMusicStore] Kayıt hatası \(filename): \(error)")
        }
    }
    
    private func loadJSON<T: Decodable>(filename: String) -> T? {
        let url = documentsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, data: data)
        } catch {
            print("[LocalMusicStore] Yükleme hatası \(filename): \(error)")
            return nil
        }
    }
    
    // MARK: - Track Operations
    func addTrack(_ track: Track) {
        if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
            tracks[idx] = track
        } else {
            tracks.insert(track, at: 0)
        }
        saveData()
    }
    
    func updateTrack(id: String, title: String, artist: String, album: String) {
        if let idx = tracks.firstIndex(where: { $0.id == id }) {
            tracks[idx].title = title
            tracks[idx].artist = artist
            tracks[idx].album = album
            saveData()
        }
    }
    
    func deleteTrack(id: String) {
        if let track = tracks.first(where: { $0.id == id }) {
            if let localFileName = track.localFileName {
                let fileURL = audioStorageDirectory.appendingPathComponent(localFileName)
                try? FileManager.default.removeItem(at: fileURL)
            }
            if let artworkFileName = track.artworkFileName {
                let artURL = artworkStorageDirectory.appendingPathComponent(artworkFileName)
                try? FileManager.default.removeItem(at: artURL)
            }
        }
        tracks.removeAll { $0.id == id }
        // Also remove from playlists and albums
        for i in 0..<playlists.count {
            playlists[i].trackIDs.removeAll { $0 == id }
        }
        for i in 0..<albums.count {
            albums[i].trackIDs.removeAll { $0 == id }
        }
        saveData()
    }
    
    func urlForTrack(_ track: Track) -> URL? {
        guard let localFileName = track.localFileName else { return nil }
        let fileURL = audioStorageDirectory.appendingPathComponent(localFileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
    
    func artworkForTrack(_ track: Track) -> UIImage? {
        guard let artworkFileName = track.artworkFileName else { return nil }
        let artURL = artworkStorageDirectory.appendingPathComponent(artworkFileName)
        guard let data = try? Data(contentsOf: artURL) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Playlist Operations
    func createPlaylist(name: String) -> Playlist {
        let playlist = Playlist(name: name)
        playlists.append(playlist)
        saveData()
        return playlist
    }
    
    func addTrackToPlaylist(trackID: String, playlistID: String) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistID }) {
            if !playlists[idx].trackIDs.contains(trackID) {
                playlists[idx].trackIDs.append(trackID)
                saveData()
            }
        }
    }
    
    func removeTrackFromPlaylist(trackID: String, playlistID: String) {
        if let idx = playlists.firstIndex(where: { $0.id == playlistID }) {
            playlists[idx].trackIDs.removeAll { $0 == trackID }
            saveData()
        }
    }
    
    func deletePlaylist(id: String) {
        playlists.removeAll { $0.id == id }
        saveData()
    }
    
    // MARK: - Album Operations
    func createAlbum(title: String, artist: String, year: String? = nil) -> Album {
        let album = Album(title: title, artist: artist, year: year)
        albums.append(album)
        saveData()
        return album
    }
    
    func deleteAlbum(id: String) {
        albums.removeAll { $0.id == id }
        saveData()
    }
    
    // MARK: - Preloaded Sample Tracks for initial test & demo
    private func preloadSampleDemoTracks() {
        let sample1 = Track(
            title: "Cyber City Beat (Deck A)",
            artist: "DJ Antigravity",
            album: "Neon Drive 2026",
            duration: 234.0,
            bpm: 128.0,
            waveformSamples: (0..<100).map { i in
                Float(sin(Double(i) * 0.2) * 0.4 + 0.5)
            }
        )
        
        let sample2 = Track(
            title: "Night Bassline (Deck B)",
            artist: "Electro Groove",
            album: "Sub Club Sessions",
            duration: 198.0,
            bpm: 126.0,
            waveformSamples: (0..<100).map { i in
                Float(cos(Double(i) * 0.15) * 0.35 + 0.5)
            }
        )
        
        let sample3 = Track(
            title: "Midnight Cruise",
            artist: "Horizon Beats",
            album: "CarPlay Sunset",
            duration: 250.0,
            bpm: 120.0,
            waveformSamples: (0..<100).map { _ in Float.random(in: 0.2...0.8) }
        )
        
        tracks = [sample1, sample2, sample3]
        
        let initialPlaylist = Playlist(
            name: "CarPlay DJ Favorites",
            trackIDs: [sample1.id, sample2.id, sample3.id]
        )
        playlists = [initialPlaylist]
        
        let initialAlbum = Album(
            title: "Neon Drive 2026",
            artist: "DJ Antigravity",
            trackIDs: [sample1.id],
            year: "2026"
        )
        albums = [initialAlbum]
        
        saveData()
    }
}
