//
//  DJDeck.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import Combine

@MainActor
final class DJDeck: ObservableObject, Identifiable {
    let id: String // "A" or "B"
    let accentColorName: String
    
    @Published var track: Track? = nil
    @Published var isPlaying: Bool = false
    @Published var isScratching: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var pitchPercentage: Double = 0.0 // -16.0% to +16.0%
    @Published var cueTime: TimeInterval? = nil
    @Published var isCuePressed: Bool = false
    @Published var isLooping: Bool = false
    @Published var loopBeats: Int = 4
    @Published var volume: Float = 1.0
    @Published var vuLevel: Float = 0.0
    @Published var jogAngle: Double = 0.0
    
    var onPlayPauseToggled: ((Bool) -> Void)?
    var onSeekRequested: ((TimeInterval) -> Void)?
    var onPitchChanged: ((Float) -> Void)?
    var onScratchMoved: ((Float, Double) -> Void)?
    var onCueToggled: ((Bool) -> Void)?
    
    init(id: String) {
        self.id = id
        self.accentColorName = id == "A" ? "neonCyan" : "neonMagenta"
    }
    
    var effectiveBPM: Double {
        let base = track?.bpm ?? 120.0
        return base * (1.0 + (pitchPercentage / 100.0))
    }
    
    var playbackProgress: Double {
        guard duration > 0 else { return 0 }
        return min(1.0, max(0.0, currentTime / duration))
    }
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedRemainingTime: String {
        let rem = max(0, duration - currentTime)
        return "-" + formatTime(rem)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let total = Int(time)
        let m = total / 60
        let s = total % 60
        let ms = Int((time.truncatingRemainder(dividingBy: 1.0)) * 100)
        return String(format: "%02d:%02d.%02d", m, s, ms)
    }
    
    // MARK: - Deck Controls
    func loadTrack(_ newTrack: Track) {
        self.track = newTrack
        self.duration = newTrack.duration
        self.currentTime = 0
        self.isPlaying = false
        self.cueTime = 0
        self.pitchPercentage = 0.0
        self.jogAngle = 0.0
    }
    
    func togglePlayPause() {
        guard track != nil else { return }
        isPlaying.toggle()
        onPlayPauseToggled?(isPlaying)
    }
    
    func setPitch(percentage: Double) {
        pitchPercentage = max(-16.0, min(16.0, percentage))
        let playbackRate = Float(1.0 + (pitchPercentage / 100.0))
        onPitchChanged?(playbackRate)
    }
    
    func resetPitch() {
        setPitch(percentage: 0.0)
    }
    
    func setCue() {
        cueTime = currentTime
    }
    
    func pressCue() {
        guard let cue = cueTime else {
            setCue()
            return
        }
        isCuePressed = true
        seek(to: cue)
        isPlaying = true
        onCueToggled?(true)
    }
    
    func releaseCue() {
        guard isCuePressed else { return }
        isCuePressed = false
        isPlaying = false
        if let cue = cueTime {
            seek(to: cue)
        }
        onCueToggled?(false)
    }
    
    func toggleLoop() {
        isLooping.toggle()
    }
    
    func setLoopBeats(_ beats: Int) {
        loopBeats = beats
    }
    
    func seek(to time: TimeInterval) {
        let clamped = max(0, min(duration, time))
        currentTime = clamped
        onSeekRequested?(clamped)
    }
    
    func seekByProgress(_ progress: Double) {
        let target = duration * max(0.0, min(1.0, progress))
        seek(to: target)
    }
    
    func processScratch(deltaAngle: Double, scratchSpeed: Float) {
        jogAngle += deltaAngle
        onScratchMoved?(scratchSpeed, deltaAngle)
    }
}
