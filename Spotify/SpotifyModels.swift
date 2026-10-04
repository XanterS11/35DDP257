//
//  SpotifyModels.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation

struct SpotifyUser: Codable {
    let id: String
    let displayName: String?
    let email: String?
    let product: String? // "premium" or "free"
    let images: [SpotifyImage]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case product
        case images
    }
}

struct SpotifyImage: Codable {
    let url: String
    let height: Int?
    let width: Int?
}

struct SpotifyPlaylistPaging: Codable {
    let items: [SpotifyPlaylist]
    let total: Int
}

struct SpotifyPlaylist: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]?
    let uri: String
    let tracks: SpotifyTracksInfo?
}

struct SpotifyTracksInfo: Codable {
    let total: Int
}

struct SpotifyPlaylistTrackItem: Codable {
    let track: SpotifyTrack?
}

struct SpotifyTrack: Identifiable, Codable {
    let id: String
    let name: String
    let uri: String
    let durationMs: Int
    let artists: [SpotifyArtist]
    let album: SpotifyAlbumSimple?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case uri
        case durationMs = "duration_ms"
        case artists
        case album
    }
    
    var artistNames: String {
        artists.map { $0.name }.joined(separator: ", ")
    }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyAlbumSimple: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]?
}

struct SpotifyAudioFeatures: Codable {
    let id: String
    let tempo: Double // BPM
    let key: Int
    let danceability: Double
    let energy: Double
}
