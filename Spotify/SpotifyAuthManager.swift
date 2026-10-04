//
//  SpotifyAuthManager.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import CryptoKit
import AuthenticationServices
import Combine

@MainActor
final class SpotifyAuthManager: NSObject, ObservableObject {
    static let shared = SpotifyAuthManager()
    
    // Geliştirici Dashboard Bilgileri
    @Published var clientID: String = "YOUR_SPOTIFY_CLIENT_ID"
    @Published var redirectURI: String = "antigravity-dj://spotify-callback"
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: SpotifyUser? = nil
    @Published var authError: String? = nil
    
    private let tokenKey = "spotify_access_token"
    private let refreshTokenKey = "spotify_refresh_token"
    private var codeVerifier: String = ""
    
    private override init() {
        super.init()
        checkStoredToken()
    }
    
    var accessToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func checkStoredToken() {
        if let token = accessToken, !token.isEmpty {
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    // MARK: - PKCE Helper Functions
    private func generateRandomString(length: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~"
        return String((0..<length).compactMap { _ in characters.randomElement() })
    }
    
    private func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else { return "" }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    // MARK: - OAuth Flow Initiation
    func startOAuthFlow() {
        codeVerifier = generateRandomString(length: 64)
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        
        let scopes = [
            "user-read-private",
            "user-read-email",
            "playlist-read-private",
            "playlist-read-collaborative",
            "user-library-read",
            "user-read-playback-state",
            "user-modify-playback-state"
        ].joined(separator: "%20")
        
        guard let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let authURL = URL(string: "https://accounts.spotify.com/authorize?response_type=code&client_id=\(clientID)&scope=\(scopes)&redirect_uri=\(encodedRedirect)&code_challenge_method=S256&code_challenge=\(codeChallenge)") else {
            authError = "Geçersiz yetkilendirme bağlantısı"
            return
        }
        
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "antigravity-dj") { [weak self] callbackURL, error in
            guard let self = self else { return }
            if let error = error {
                Task { @MainActor in
                    self.authError = "Giriş iptal edildi: \(error.localizedDescription)"
                }
                return
            }
            if let callbackURL = callbackURL {
                Task { @MainActor in
                    await self.handleCallback(url: callbackURL)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    // MARK: - Handle Callback URL & Token Exchange
    func handleCallback(url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            authError = "Yetkilendirme kodu alınamadı"
            return
        }
        
        await exchangeCodeForToken(code: code)
    }
    
    private func exchangeCodeForToken(code: String) async {
        guard let tokenURL = URL(string: "https://accounts.spotify.com/api/token") else { return }
        
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyParameters: [String: String] = [
            "client_id": clientID,
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURI,
            "code_verifier": codeVerifier
        ]
        
        let bodyString = bodyParameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let token = json["access_token"] as? String {
                UserDefaults.standard.set(token, forKey: tokenKey)
                if let refresh = json["refresh_token"] as? String {
                    UserDefaults.standard.set(refresh, forKey: refreshTokenKey)
                }
                self.isAuthenticated = true
                self.authError = nil
            }
        } catch {
            self.authError = "Token alışverişi başarısız: \(error.localizedDescription)"
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isAuthenticated = false
        currentUser = nil
    }
}

extension SpotifyAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}
