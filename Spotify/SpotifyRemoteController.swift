//
//  SpotifyRemoteController.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import Combine

@MainActor
final class SpotifyRemoteController: ObservableObject {
    static let shared = SpotifyRemoteController()
    
    @Published var isPlaying: Bool = false
    @Published var currentTrackTitle: String = ""
    @Published var currentArtist: String = ""
    @Published var currentArtworkURL: String? = nil
    @Published var progressMs: Int = 0
    @Published var durationMs: Int = 0
    @Published var statusMessage: String? = nil
    
    private let auth = SpotifyAuthManager.shared
    private var statePollingTimer: AnyCancellable?
    
    private init() {
        startPlaybackStatePolling()
    }
    
    func playTrack(uri: String) async {
        guard auth.isAuthenticated else {
            statusMessage = "Spotify hesabı bağlı değil."
            return
        }
        
        let endpoint = "https://api.spotify.com/v1/me/player/play"
        guard let url = URL(string: endpoint) else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(auth.accessToken ?? "")", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["uris": [uri]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse, http.statusCode == 204 || http.statusCode == 200 {
                isPlaying = true
                statusMessage = "Spotify çalınıyor"
            } else {
                statusMessage = "Aktif Spotify cihazı bulunamadı. Spotify uygulamasını açın."
            }
        } catch {
            statusMessage = "Oynatma hatası: \(error.localizedDescription)"
        }
    }
    
    func pause() async {
        await executeSimpleCommand(endpoint: "pause", method: "PUT")
        isPlaying = false
    }
    
    func resume() async {
        await executeSimpleCommand(endpoint: "play", method: "PUT")
        isPlaying = true
    }
    
    func skipNext() async {
        await executeSimpleCommand(endpoint: "next", method: "POST")
    }
    
    func skipPrevious() async {
        await executeSimpleCommand(endpoint: "previous", method: "POST")
    }
    
    private func executeSimpleCommand(endpoint: String, method: String) async {
        guard let token = auth.accessToken, !token.isEmpty else { return }
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/\(endpoint)") else { return }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        _ = try? await URLSession.shared.data(for: req)
    }
    
    private func startPlaybackStatePolling() {
        statePollingTimer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchCurrentPlayback()
                }
            }
    }
    
    func fetchCurrentPlayback() async {
        guard auth.isAuthenticated, let token = auth.accessToken, !token.isEmpty else { return }
        guard let url = URL(string: "https://api.spotify.com/v1/me/player") else { return }
        
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            return
        }
        
        struct PlaybackResponse: Codable {
            let is_playing: Bool
            let progress_ms: Int?
            let item: SpotifyTrack?
        }
        
        if let state = try? JSONDecoder().decode(PlaybackResponse.self, data: data) {
            self.isPlaying = state.is_playing
            self.progressMs = state.progress_ms ?? 0
            if let item = state.item {
                self.currentTrackTitle = item.name
                self.currentArtist = item.artistNames
                self.durationMs = item.durationMs
                self.currentArtworkURL = item.album?.images?.first?.url
            }
        }
    }
}
