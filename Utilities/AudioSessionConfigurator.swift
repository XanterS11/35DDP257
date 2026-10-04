//
//  AudioSessionConfigurator.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import AVFoundation

final class AudioSessionConfigurator {
    static let shared = AudioSessionConfigurator()
    private init() {}
    
    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
            )
            try session.setActive(true)
            
            setupInterruptionObserver()
            setupRouteChangeObserver()
        } catch {
            print("[AudioSessionConfigurator] Oturum başlatma hatası: \(error)")
        }
    }
    
    // MARK: - Audio Interruptions (Phone Calls, Siri, Navigation Ducking)
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }
            
            switch type {
            case .began:
                print("[AudioSession] Ses kesintisi başladı (Arama/Siri vb.).")
            case .ended:
                guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    print("[AudioSession] Kesinti bitti, oynatmaya devam edilebilir.")
                    AudioEngineManager.shared.startEngine()
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Route Changes (CarPlay USB/Bluetooth Connect/Disconnect)
    private func setupRouteChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
            }
            
            switch reason {
            case .newDeviceAvailable:
                print("[AudioSession] Yeni ses çıkışı bağlandı (CarPlay / Araç Bluetooth).")
            case .oldDeviceUnavailable:
                print("[AudioSession] Ses çıkışı ayrıldı. Güvenlik için ses duraklatıldı.")
                if AudioEngineManager.shared.deckA.isPlaying {
                    AudioEngineManager.shared.deckA.togglePlayPause()
                }
                if AudioEngineManager.shared.deckB.isPlaying {
                    AudioEngineManager.shared.deckB.togglePlayPause()
                }
            default:
                break
            }
        }
    }
}
