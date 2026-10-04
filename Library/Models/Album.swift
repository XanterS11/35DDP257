//
//  Album.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation

struct Album: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var artist: String
    var trackIDs: [String]
    var year: String?
    var artworkFileName: String?
    var sourceURL: String?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        artist: String,
        trackIDs: [String] = [],
        year: String? = nil,
        artworkFileName: String? = nil,
        sourceURL: String? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.trackIDs = trackIDs
        self.year = year
        self.artworkFileName = artworkFileName
        self.sourceURL = sourceURL
    }
}
