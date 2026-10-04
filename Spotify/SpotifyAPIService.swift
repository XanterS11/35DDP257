//
//  SpotifyAPIService.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation

final class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    private init() {}
    
    private let baseURL = "https://api.spotify.com/v1"
    
    private func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> (Data, HTTPURLResponse) {
        guard let token = await SpotifyAuthManager.shared.accessToken, !token.isEmpty else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, httpResponse)
    }
    
    // MARK: - Current User
    func fetchUserProfile() async throws -> SpotifyUser {
        let (data, _) = try await makeRequest(endpoint: "me")
        return try JSONDecoder().decode(SpotifyUser.self, data: data)
    }
    
    // MARK: - Playlists
    func fetchUserPlaylists(limit: Int = 20) async throws -> [SpotifyPlaylist] {
        let (data, _) = try await makeRequest(endpoint: "me/playlists?limit=\(limit)")
        let paging = try JSONDecoder().decode(SpotifyPlaylistPaging.self, data: data)
        return paging.items
    }
    
    // MARK: - Playlist Tracks
    func fetchPlaylistTracks(playlistID: String) async throws -> [SpotifyTrack] {
        let (data, _) = try await makeRequest(endpoint: "playlists/\(playlistID)/tracks")
        
        struct PlaylistItemsResponse: Codable {
            let items: [SpotifyPlaylistTrackItem]
        }
        
        let res = try JSONDecoder().decode(PlaylistItemsResponse.self, data: data)
        return res.items.compactMap { $0.track }
    }
    
    // MARK: - Audio Features (BPM / Tempo)
    func fetchAudioFeatures(trackID: String) async throws -> SpotifyAudioFeatures {
        let (data, _) = try await makeRequest(endpoint: "audio-features/\(trackID)")
        return try JSONDecoder().decode(SpotifyAudioFeatures.self, data: data)
    }
}
