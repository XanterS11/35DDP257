//
//  CarPlayTemplateManager.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import CarPlay

@MainActor
final class CarPlayTemplateManager {
    static let shared = CarPlayTemplateManager()
    private init() {}
    
    private var interfaceController: CPInterfaceController?
    private let djController = CarPlayDJController.shared
    private let audioEngine = AudioEngineManager.shared
    private let store = LocalMusicStore.shared
    
    func setInterfaceController(_ controller: CPInterfaceController) {
        self.interfaceController = controller
        configureNowPlayingTemplate()
    }
    
    // MARK: - Root Tab Bar Template (Apple CarPlay Compliant)
    func createRootTemplate() -> CPTemplate {
        let mainMenuTab = createCarPlayHubTemplate()
        let djMixTab = createDJMixTemplate()
        let playlistTab = createPlaylistsTemplate()
        let albumsTab = createAlbumsTemplate()
        let allTracksTab = createAllTracksTemplate()
        
        let tabBar = CPTabBarTemplate(templates: [mainMenuTab, djMixTab, playlistTab, albumsTab, allTracksTab])
        return tabBar
    }
    
    // MARK: - Tab 0: In-Car Hub Launchpad (Açıldığında direkt DJ arayüzü gelmez, kullanıcı istediğinde girer)
    private func createCarPlayHubTemplate() -> CPListTemplate {
        let enterDJItem = CPListItem(
            text: "🎛️ DJ Konsoluna Gir",
            detailText: "35 DDP 257 Mikser & Scratch arayüzünü başlat"
        )
        enterDJItem.handler = { [weak self] _, completion in
            if let iface = self?.interfaceController, let djTemplate = self?.createDJMixTemplate() {
                iface.pushTemplate(djTemplate, animated: true, completion: nil)
            }
            completion()
        }
        
        let spotifyItem = CPListItem(
            text: "🎵 Spotify Çalan Parça",
            detailText: "CarPlay Now Playing ekranını aç"
        )
        spotifyItem.handler = { [weak self] _, completion in
            if let iface = self?.interfaceController {
                iface.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
            completion()
        }
        
        let exitItem = CPListItem(
            text: "🚪 CarPlay'den Çıkış Yap",
            detailText: "Konsolu kapat ve ses motorunu durdur"
        )
        exitItem.handler = { [weak self] _, completion in
            self?.audioEngine.stopAllAudio()
            self?.interfaceController?.popToRootTemplate(animated: true, completion: nil)
            completion()
        }
        
        let section = CPListSection(items: [enterDJItem, spotifyItem, exitItem], header: "BMW 35 DDP 257 • CARPLAY HUB", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Ana Menü", sections: [section])
        template.tabTitle = "Ana Menü"
        template.tabImage = UIImage(systemName: "car.fill")
        return template
    }
    
    // MARK: - Tab 1: In-Car DJ Mix Controller
    private func createDJMixTemplate() -> CPListTemplate {
        let activeDeck = audioEngine.crossfaderPosition < 0.5 ? "Deck A" : "Deck B"
        let oppDeck = audioEngine.crossfaderPosition < 0.5 ? "Deck B" : "Deck A"
        
        let quickMixItem = CPListItem(
            text: "DJ Auto Mix ➔ \(oppDeck)",
            detailText: "Kesintisiz geçiş yap (Crossfade)"
        )
        quickMixItem.handler = { [weak self] _, completion in
            self?.djController.triggerQuickMix()
            completion()
        }
        
        let togglePlayItem = CPListItem(
            text: "Oynat / Duraklat (\(activeDeck))",
            detailText: "Aktif deck çalma durumunu değiştir"
        )
        togglePlayItem.handler = { [weak self] _, completion in
            self?.djController.playPauseCurrentDeck()
            completion()
        }
        
        let cueDeckAItem = CPListItem(
            text: "CUE ➔ Deck A",
            detailText: "Deck A başlangıç noktasına dön"
        )
        cueDeckAItem.handler = { [weak self] _, completion in
            self?.djController.cueDeckA()
            completion()
        }
        
        let cueDeckBItem = CPListItem(
            text: "CUE ➔ Deck B",
            detailText: "Deck B başlangıç noktasına dön"
        )
        cueDeckBItem.handler = { [weak self] _, completion in
            self?.djController.cueDeckB()
            completion()
        }
        
        let nowPlayingShortcut = CPListItem(
            text: "Çalan Parça Ekranı",
            detailText: "CarPlay Now Playing konsoluna git"
        )
        nowPlayingShortcut.handler = { [weak self] _, completion in
            if let iface = self?.interfaceController {
                iface.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
            }
            completion()
        }
        
        let exitDJItem = CPListItem(
            text: "🚪 DJ Konsolundan Çıkış Yap",
            detailText: "Ana menüye dön ve bekleme moduna geç"
        )
        exitDJItem.handler = { [weak self] _, completion in
            self?.audioEngine.stopAllAudio()
            self?.interfaceController?.popToRootTemplate(animated: true, completion: nil)
            completion()
        }
        
        let section = CPListSection(items: [quickMixItem, togglePlayItem, cueDeckAItem, cueDeckBItem, nowPlayingShortcut, exitDJItem], header: "ARAÇ İÇİ DJ KONTROLLERİ", sectionIndexTitle: nil)
        
        let template = CPListTemplate(title: "DJ Konsol", sections: [section])
        template.tabTitle = "DJ Konsol"
        template.tabImage = UIImage(systemName: "opticaldisc")
        return template
    }
    
    // MARK: - Tab 2: Playlists Template
    private func createPlaylistsTemplate() -> CPListTemplate {
        let items: [CPListItem] = store.playlists.map { playlist in
            let item = CPListItem(
                text: playlist.name,
                detailText: "\(playlist.trackIDs.count) Şarkı"
            )
            item.handler = { [weak self] _, completion in
                self?.showPlaylistTracks(playlist)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Playlistler", sections: [section])
        template.tabTitle = "Playlistler"
        template.tabImage = UIImage(systemName: "music.note.list")
        return template
    }
    
    private func showPlaylistTracks(_ playlist: Playlist) {
        let tracks = store.tracks.filter { playlist.trackIDs.contains($0.id) }
        let items: [CPListItem] = tracks.map { track in
            let item = CPListItem(text: track.title, detailText: "\(track.artist) • \(track.formattedDuration)")
            item.handler = { [weak self] _, completion in
                self?.djController.loadTrackIntoActiveDeck(track)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: playlist.name, sections: [section])
        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    // MARK: - Tab 3: Albums Template
    private func createAlbumsTemplate() -> CPListTemplate {
        let items: [CPListItem] = store.albums.map { album in
            let item = CPListItem(
                text: album.title,
                detailText: "\(album.artist) • \(album.trackIDs.count) Şarkı"
            )
            item.handler = { [weak self] _, completion in
                self?.showAlbumTracks(album)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Albümler", sections: [section])
        template.tabTitle = "Albümler"
        template.tabImage = UIImage(systemName: "square.stack.fill")
        return template
    }
    
    private func showAlbumTracks(_ album: Album) {
        let tracks = store.tracks.filter { album.trackIDs.contains($0.id) }
        let items: [CPListItem] = tracks.map { track in
            let item = CPListItem(text: track.title, detailText: "\(track.artist) • \(track.formattedDuration)")
            item.handler = { [weak self] _, completion in
                self?.djController.loadTrackIntoActiveDeck(track)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let listTemplate = CPListTemplate(title: album.title, sections: [section])
        interfaceController?.pushTemplate(listTemplate, animated: true, completion: nil)
    }
    
    // MARK: - Tab 4: All Tracks
    private func createAllTracksTemplate() -> CPListTemplate {
        let items: [CPListItem] = store.tracks.map { track in
            let item = CPListItem(
                text: track.title,
                detailText: "\(track.artist) • \(track.formattedDuration)"
            )
            item.handler = { [weak self] _, completion in
                self?.djController.loadTrackIntoActiveDeck(track)
                completion()
            }
            return item
        }
        
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Şarkılar", sections: [section])
        template.tabTitle = "Şarkılar"
        template.tabImage = UIImage(systemName: "music.note")
        return template
    }
    
    // MARK: - Configure Now Playing Screen
    private func configureNowPlayingTemplate() {
        let nowPlaying = CPNowPlayingTemplate.shared
        
        // Add custom DJ quick mix button to CarPlay NowPlaying screen
        let mixButton = CPNowPlayingImageButton(image: UIImage(systemName: "bolt.horizontal.fill") ?? UIImage()) { [weak self] _ in
            self?.djController.triggerQuickMix()
        }
        
        nowPlaying.updateNowPlayingButtons([mixButton])
    }
}
