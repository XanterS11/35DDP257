//
//  MusicFileManager.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

final class MusicFileManager {
    static let shared = MusicFileManager()
    private init() {}
    
    // Supported audio content types: MP3, M4A, WAV, AAC, AIFF
    static let supportedAudioTypes: [UTType] = [
        .mp3,
        UTType(filenameExtension: "m4a") ?? .audio,
        .wav,
        UTType(filenameExtension: "aac") ?? .audio,
        .aiff
    ]
    
    func importAudioFile(from sourceURL: URL) async -> Track? {
        let isSecurityScoped = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let store = await LocalMusicStore.shared
        let ext = sourceURL.pathExtension.lowercased()
        let uniqueID = UUID().uuidString
        let destFileName = "\(uniqueID).\(ext)"
        let destURL = await store.audioStorageDirectory.appendingPathComponent(destFileName)
        
        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            print("[MusicFileManager] Dosya kopyalama hatası: \(error)")
            return nil
        }
        
        // Extract metadata
        let metadata = await ID3MetadataReader.shared.extractMetadata(from: destURL)
        
        // Save artwork if present
        var artworkFileName: String? = nil
        if let artData = metadata.artworkData {
            let artName = "\(uniqueID)_artwork.jpg"
            let artURL = await store.artworkStorageDirectory.appendingPathComponent(artName)
            try? artData.write(to: artURL)
            artworkFileName = artName
        }
        
        // Extract waveform data
        let samples = await WaveformExtractor.shared.extractWaveform(from: destURL, sampleCount: 100)
        
        let track = Track(
            id: uniqueID,
            title: metadata.title,
            artist: metadata.artist,
            album: metadata.album,
            duration: metadata.duration,
            bpm: 124.0, // Varsayılan veya audio analyzer hesaplayabilir
            localFileName: destFileName,
            artworkFileName: artworkFileName,
            waveformSamples: samples,
            isSpotify: false,
            dateAdded: Date()
        )
        
        await store.addTrack(track)
        return track
    }
}

// SwiftUI Document Picker Coordinator
struct DocumentPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(
            forOpeningContentTypes: MusicFileManager.supportedAudioTypes,
            asCopy: true
        )
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPickerView
        
        init(_ parent: DocumentPickerView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            parent.onPick(url)
        }
    }
}
