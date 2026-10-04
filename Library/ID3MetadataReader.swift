//
//  ID3MetadataReader.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import AVFoundation
import UIKit

final class ID3MetadataReader {
    static let shared = ID3MetadataReader()
    private init() {}
    
    struct ExtractedMetadata {
        var title: String
        var artist: String
        var album: String
        var duration: TimeInterval
        var artworkData: Data?
    }
    
    func extractMetadata(from url: URL) async -> ExtractedMetadata {
        let asset = AVURLAsset(url: url)
        
        var title = url.deletingPathExtension().lastPathComponent
        var artist = "Bilinmeyen Sanatçı"
        var album = "Bilinmeyen Albüm"
        var duration: TimeInterval = 0
        var artworkData: Data? = nil
        
        do {
            let dur = try await asset.load(.duration)
            duration = CMTimeGetSeconds(dur)
            
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                guard let commonKey = item.commonKey else { continue }
                
                switch commonKey {
                case .commonKeyTitle:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        title = val
                    }
                case .commonKeyArtist:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        artist = val
                    }
                case .commonKeyAlbumName:
                    if let val = try? await item.load(.stringValue), !val.trimmingCharacters(in: .whitespaces).isEmpty {
                        album = val
                    }
                case .commonKeyArtwork:
                    if let dataVal = try? await item.load(.dataValue) {
                        artworkData = dataVal
                    }
                default:
                    break
                }
            }
        } catch {
            print("[ID3MetadataReader] Metadata okunamadı: \(error)")
        }
        
        return ExtractedMetadata(
            title: title,
            artist: artist,
            album: album,
            duration: duration,
            artworkData: artworkData
        )
    }
}
