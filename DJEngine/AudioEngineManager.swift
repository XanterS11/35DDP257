//
//  AudioEngineManager.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
final class AudioEngineManager: ObservableObject {
    static let shared = AudioEngineManager()
    
    // Decks
    @Published var deckA = DJDeck(id: "A")
    @Published var deckB = DJDeck(id: "B")
    
    // Mixer State
    @Published var crossfaderPosition: Float = 0.5 // 0.0: Deck A 100%, 1.0: Deck B 100%
    @Published var masterVolume: Float = 0.85
    @Published var isMuted: Bool = false
    @Published var isEngineRunning: Bool = false
    
    // Core Audio Engine
    private let engine = AVAudioEngine()
    
    private let playerNodeA = AVAudioPlayerNode()
    private let playerNodeB = AVAudioPlayerNode()
    
    private let varispeedA = AVAudioUnitVarispeed()
    private let varispeedB = AVAudioUnitVarispeed()
    
    private let mixerDeckA = AVAudioMixerNode()
    private let mixerDeckB = AVAudioMixerNode()
    
    private var audioFileA: AVAudioFile?
    private var audioFileB: AVAudioFile?
    
    private var displayLinkTimer: AnyCancellable?
    
    private init() {
        setupAudioSession()
        setupAudioGraph()
        setupDeckHandlers()
        setupRemoteCommands()
        startEngine()
        startPlaybackPolling()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("[AudioEngine] AVAudioSession hatası: \(error)")
        }
    }
    
    // MARK: - Audio Graph Connection
    private func setupAudioGraph() {
        engine.attach(playerNodeA)
        engine.attach(varispeedA)
        engine.attach(mixerDeckA)
        
        engine.attach(playerNodeB)
        engine.attach(varispeedB)
        engine.attach(mixerDeckB)
        
        let mainMixer = engine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        
        // Chain A: PlayerA -> VarispeedA -> MixerA -> MainMixer
        engine.connect(playerNodeA, to: varispeedA, format: nil)
        engine.connect(varispeedA, to: mixerDeckA, format: nil)
        engine.connect(mixerDeckA, to: mainMixer, format: format)
        
        // Chain B: PlayerB -> VarispeedB -> MixerB -> MainMixer
        engine.connect(playerNodeB, to: varispeedB, format: nil)
        engine.connect(varispeedB, to: mixerDeckB, format: nil)
        engine.connect(mixerDeckB, to: mainMixer, format: format)
        
        updateMixerVolumes()
    }
    
    func startEngine() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
            isEngineRunning = true
        } catch {
            print("[AudioEngine] Engine başlatılamadı: \(error)")
        }
    }
    
    // MARK: - Deck Binding Handlers
    private func setupDeckHandlers() {
        // Deck A Bindings
        deckA.onPlayPauseToggled = { [weak self] isPlaying in
            self?.handlePlayPause(deckId: "A", isPlaying: isPlaying)
        }
        deckA.onSeekRequested = { [weak self] time in
            self?.seekDeck(deckId: "A", to: time)
        }
        deckA.onPitchChanged = { [weak self] rate in
            self?.varispeedA.rate = rate
        }
        deckA.onScratchMoved = { [weak self] scratchSpeed, _ in
            self?.handleScratch(deckId: "A", speed: scratchSpeed)
        }
        
        // Deck B Bindings
        deckB.onPlayPauseToggled = { [weak self] isPlaying in
            self?.handlePlayPause(deckId: "B", isPlaying: isPlaying)
        }
        deckB.onSeekRequested = { [weak self] time in
            self?.seekDeck(deckId: "B", to: time)
        }
        deckB.onPitchChanged = { [weak self] rate in
            self?.varispeedB.rate = rate
        }
        deckB.onScratchMoved = { [weak self] scratchSpeed, _ in
            self?.handleScratch(deckId: "B", speed: scratchSpeed)
        }
    }
    
    // MARK: - Loading Audio into Decks
    func loadTrackIntoDeck(_ track: Track, deckId: String) {
        let store = LocalMusicStore.shared
        guard let url = store.urlForTrack(track) else {
            // Demo track or sample fallback: load virtual track
            if deckId == "A" {
                deckA.loadTrack(track)
            } else {
                deckB.loadTrack(track)
            }
            return
        }
        
        do {
            let audioFile = try AVAudioFile(forReading: url)
            if deckId == "A" {
                audioFileA = audioFile
                deckA.loadTrack(track)
                scheduleFile(player: playerNodeA, file: audioFile, fromTime: 0)
            } else {
                audioFileB = audioFile
                deckB.loadTrack(track)
                scheduleFile(player: playerNodeB, file: audioFile, fromTime: 0)
            }
            updateNowPlayingInfo()
        } catch {
            print("[AudioEngine] Ses dosyası yüklenemedi: \(error)")
        }
    }
    
    private func scheduleFile(player: AVAudioPlayerNode, file: AVAudioFile, fromTime: TimeInterval) {
        player.stop()
        let sampleRate = file.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(fromTime * sampleRate)
        let totalFrames = file.length
        
        guard startFrame < totalFrames else { return }
        let frameCount = AVAudioFrameCount(totalFrames - startFrame)
        
        player.scheduleSegment(file, startingFrame: startFrame, frameCount: frameCount, at: nil) {
            // Segment finished callback
        }
    }
    
    // MARK: - Playback Logic
    private func handlePlayPause(deckId: String, isPlaying: Bool) {
        startEngine()
        if deckId == "A" {
            if isPlaying {
                playerNodeA.play()
            } else {
                playerNodeA.pause()
            }
        } else {
            if isPlaying {
                playerNodeB.play()
            } else {
                playerNodeB.pause()
            }
        }
        updateNowPlayingInfo()
    }
    
    private func seekDeck(deckId: String, to time: TimeInterval) {
        if deckId == "A", let file = audioFileA {
            let wasPlaying = deckA.isPlaying
            scheduleFile(player: playerNodeA, file: file, fromTime: time)
            if wasPlaying { playerNodeA.play() }
        } else if deckId == "B", let file = audioFileB {
            let wasPlaying = deckB.isPlaying
            scheduleFile(player: playerNodeB, file: file, fromTime: time)
            if wasPlaying { playerNodeB.play() }
        }
        updateNowPlayingInfo()
    }
    
    private func handleScratch(deckId: String, speed: Float) {
        if deckId == "A" {
            let targetRate = max(0.1, abs(speed))
            varispeedA.rate = targetRate
            // Rotate jog and advance time smoothly
            deckA.currentTime = max(0, min(deckA.duration, deckA.currentTime + Double(speed * 0.05)))
        } else {
            let targetRate = max(0.1, abs(speed))
            varispeedB.rate = targetRate
            deckB.currentTime = max(0, min(deckB.duration, deckB.currentTime + Double(speed * 0.05)))
        }
    }
    
    // MARK: - Crossfader & Volume
    func setCrossfader(_ position: Float) {
        crossfaderPosition = max(0.0, min(1.0, position))
        updateMixerVolumes()
    }
    
    func setMasterVolume(_ vol: Float) {
        masterVolume = max(0.0, min(1.0, vol))
        updateMixerVolumes()
    }
    
    func toggleMute() {
        isMuted.toggle()
        updateMixerVolumes()
    }
    
    private func updateMixerVolumes() {
        if isMuted {
            mixerDeckA.outputVolume = 0
            mixerDeckB.outputVolume = 0
            return
        }
        
        // Equal-Power Crossfade Curve: cos/sin profile
        let angle = Double(crossfaderPosition) * (.pi / 2.0)
        let volA = Float(cos(angle)) * masterVolume * deckA.volume
        let volB = Float(sin(angle)) * masterVolume * deckB.volume
        
        mixerDeckA.outputVolume = volA
        mixerDeckB.outputVolume = volB
    }
    
    // MARK: - Playback Timer & VU Meter Emulation
    private func startPlaybackPolling() {
        displayLinkTimer = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePlaybackProgress()
            }
    }
    
    private func updatePlaybackProgress() {
        if deckA.isPlaying && !deckA.isScratching {
            let rate = Double(varispeedA.rate)
            deckA.currentTime = min(deckA.duration, deckA.currentTime + 0.05 * rate)
            deckA.jogAngle += (360.0 / (60.0 / deckA.effectiveBPM * 4.0)) * 0.05
            deckA.vuLevel = Float.random(in: 0.6...0.95) * (1.0 - crossfaderPosition)
            if deckA.currentTime >= deckA.duration && deckA.duration > 0 {
                deckA.isPlaying = false
                deckA.currentTime = 0
            }
        } else {
            deckA.vuLevel = max(0, deckA.vuLevel - 0.1)
        }
        
        if deckB.isPlaying && !deckB.isScratching {
            let rate = Double(varispeedB.rate)
            deckB.currentTime = min(deckB.duration, deckB.currentTime + 0.05 * rate)
            deckB.jogAngle += (360.0 / (60.0 / deckB.effectiveBPM * 4.0)) * 0.05
            deckB.vuLevel = Float.random(in: 0.6...0.95) * crossfaderPosition
            if deckB.currentTime >= deckB.duration && deckB.duration > 0 {
                deckB.isPlaying = false
                deckB.currentTime = 0
            }
        } else {
            deckB.vuLevel = max(0, deckB.vuLevel - 0.1)
        }
    }
    
    // MARK: - MPNowPlayingInfoCenter & MPRemoteCommandCenter (CarPlay & Lock Screen)
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.crossfaderPosition < 0.5 {
                self.deckA.togglePlayPause()
            } else {
                self.deckB.togglePlayPause()
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.crossfaderPosition < 0.5 {
                self.deckA.togglePlayPause()
            } else {
                self.deckB.togglePlayPause()
            }
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            // Quick Mix: Crossfade to other deck
            guard let self = self else { return .commandFailed }
            self.autoCrossfadeToNextDeck()
            return .success
        }
    }
    
    func autoCrossfadeToNextDeck() {
        withAnimation(.easeInOut(duration: 1.5)) {
            if crossfaderPosition < 0.5 {
                if !deckB.isPlaying { deckB.togglePlayPause() }
                setCrossfader(1.0)
            } else {
                if !deckA.isPlaying { deckA.togglePlayPause() }
                setCrossfader(0.0)
            }
        }
    }
    
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()
        let activeDeck = crossfaderPosition < 0.5 ? deckA : deckB
        guard let track = activeDeck.track else { return }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "\(track.artist) [Deck \(activeDeck.id)]"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = activeDeck.currentTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = activeDeck.isPlaying ? 1.0 : 0.0
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
