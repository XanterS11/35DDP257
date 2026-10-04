//
//  Playlist.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation

struct Playlist: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var name: String
    var trackIDs: [String]
    var createdAt: Date
    var artworkFileName: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        trackIDs: [String] = [],
        createdAt: Date = Date(),
        artworkFileName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.trackIDs = trackIDs
        self.createdAt = createdAt
        self.artworkFileName = artworkFileName
    }
}
