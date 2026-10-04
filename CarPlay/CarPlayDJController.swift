//
//  CarPlayDJController.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import CarPlay

@MainActor
final class CarPlayDJController {
    static let shared = CarPlayDJController()
    private init() {}
    
    private let audioEngine = AudioEngineManager.shared
    private let store = LocalMusicStore.shared
    
    // Quick Mix: Smoothly blends from current deck to the opposite deck
    func triggerQuickMix() {
        audioEngine.autoCrossfadeToNextDeck()
    }
    
    func playPauseCurrentDeck() {
        if audioEngine.crossfaderPosition < 0.5 {
            audioEngine.deckA.togglePlayPause()
        } else {
            audioEngine.deckB.togglePlayPause()
        }
    }
    
    func cueDeckA() {
        audioEngine.deckA.pressCue()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.audioEngine.deckA.releaseCue()
        }
    }
    
    func cueDeckB() {
        audioEngine.deckB.pressCue()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.audioEngine.deckB.releaseCue()
        }
    }
    
    func loadTrackIntoActiveDeck(_ track: Track) {
        if audioEngine.crossfaderPosition < 0.5 {
            audioEngine.loadTrackIntoDeck(track, deckId: "B")
        } else {
            audioEngine.loadTrackIntoDeck(track, deckId: "A")
        }
    }
}
