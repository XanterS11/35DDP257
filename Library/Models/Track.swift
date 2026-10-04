//
//  Track.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation

struct Track: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var bpm: Double
    var localFileName: String?
    var artworkFileName: String?
    var waveformSamples: [Float]
    var isSpotify: Bool
    var spotifyURI: String?
    var dateAdded: Date
    
    init(
        id: String = UUID().uuidString,
        title: String,
        artist: String = "Bilinmeyen Sanatçı",
        album: String = "Bilinmeyen Albüm",
        duration: TimeInterval = 0,
        bpm: Double = 120.0,
        localFileName: String? = nil,
        artworkFileName: String? = nil,
        waveformSamples: [Float] = [],
        isSpotify: Bool = false,
        spotifyURI: String? = nil,
        dateAdded: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.bpm = bpm
        self.localFileName = localFileName
        self.artworkFileName = artworkFileName
        self.waveformSamples = waveformSamples
        self.isSpotify = isSpotify
        self.spotifyURI = spotifyURI
        self.dateAdded = dateAdded
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    static func sample(deck: String) -> Track {
        Track(
            title: deck == "A" ? "Neon Cyberdrive" : "Midnight Electro",
            artist: deck == "A" ? "SynthWave Project" : "Deep Groove Lab",
            album: "Club Nights Vol. 1",
            duration: 215.0,
            bpm: deck == "A" ? 128.0 : 124.0,
            waveformSamples: (0..<80).map { _ in Float.random(in: 0.15...0.95) }
        )
    }
}
