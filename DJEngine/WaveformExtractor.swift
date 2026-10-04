//
//  WaveformExtractor.swift
//  35DDP257 - iOS + CarPlay DJ Application
//

import Foundation
import AVFoundation

final class WaveformExtractor {
    static let shared = WaveformExtractor()
    private init() {}
    
    func extractWaveform(from audioURL: URL, sampleCount: Int = 100) async -> [Float] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let file = try? AVAudioFile(forReading: audioURL) else {
                    continuation.resume(returning: (0..<sampleCount).map { _ in Float.random(in: 0.1...0.6) })
                    return
                }
                
                let format = file.processingFormat
                let frameCount = UInt32(file.length)
                guard frameCount > 0 else {
                    continuation.resume(returning: [])
                    return
                }
                
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                    continuation.resume(returning: [])
                    return
                }
                
                do {
                    try file.read(into: buffer)
                } catch {
                    continuation.resume(returning: [])
                    return
                }
                
                guard let channelData = buffer.floatChannelData?[0] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let totalFrames = Int(buffer.frameLength)
                let step = max(1, totalFrames / sampleCount)
                var samples: [Float] = []
                samples.reserveCapacity(sampleCount)
                
                for i in 0..<sampleCount {
                    let startFrame = i * step
                    let endFrame = min(startFrame + step, totalFrames)
                    if startFrame >= totalFrames { break }
                    
                    var sum: Float = 0
                    var count: Float = 0
                    for j in startFrame..<endFrame {
                        sum += abs(channelData[j])
                        count += 1
                    }
                    let avg = count > 0 ? (sum / count) : 0
                    samples.append(avg)
                }
                
                // Normalize between 0.05 and 1.0 for visual balance
                let maxVal = samples.max() ?? 1.0
                let normalized = samples.map { maxVal > 0 ? max(0.08, min(1.0, $0 / maxVal)) : 0.1 }
                
                continuation.resume(returning: normalized)
            }
        }
    }
}
