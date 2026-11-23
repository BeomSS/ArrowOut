import AVFoundation
import UIKit

/// Provides tactile haptics + lightweight procedural audio synthesis (zero external sound assets required).
public final class SystemFeedbackService: FeedbackServiceProtocol {
    public var isSoundEnabled: Bool = true
    public var isHapticsEnabled: Bool = true

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var isAudioConfigured = false

    // Pentatonic frequencies for pleasant ascending combo chimes
    private let comboNotes: [Double] = [
        523.25, // C5
        587.33, // D5
        659.25, // E5
        783.99, // G5
        880.00, // A5
        1046.50, // C6
        1174.66, // D6
        1318.51  // E6
    ]

    public init() {
        prepareHaptics()
    }

    private func prepareHaptics() {
        lightImpact.prepare()
        mediumImpact.prepare()
        rigidImpact.prepare()
        notificationFeedback.prepare()
    }

    private func ensureAudioReady() {
        guard !isAudioConfigured else {
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session failure shouldn't crash gameplay
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.mainMixerNode.outputVolume = 0.35

        do {
            try audioEngine.start()
            isAudioConfigured = true
        } catch {
            isAudioConfigured = false
        }
    }

    public func playEscape(comboIndex: Int) {
        if isHapticsEnabled {
            if comboIndex >= 3 {
                mediumImpact.impactOccurred(intensity: 0.75)
            } else {
                lightImpact.impactOccurred(intensity: 0.8)
            }
        }
        if isSoundEnabled {
            let note = comboNotes[min(max(0, comboIndex), comboNotes.count - 1)]
            playSynthesizedTone(
                startFrequency: note * 0.92,
                endFrequency: note,
                duration: 0.14,
                volume: 0.42,
                harmonicMix: 0.25
            )
        }
    }

    public func playBlocked() {
        if isHapticsEnabled {
            notificationFeedback.notificationOccurred(.error)
            rigidImpact.impactOccurred(intensity: 0.9)
        }
        if isSoundEnabled {
            playSynthesizedTone(
                startFrequency: 170,
                endFrequency: 110,
                duration: 0.16,
                volume: 0.55,
                harmonicMix: 0.45
            )
        }
    }

    public func playHint() {
        if isHapticsEnabled {
            lightImpact.impactOccurred(intensity: 0.5)
        }
        if isSoundEnabled {
            playSynthesizedTone(
                startFrequency: 740,
                endFrequency: 987.77,
                duration: 0.18,
                volume: 0.30,
                harmonicMix: 0.15
            )
        }
    }

    public func playLevelComplete() {
        if isHapticsEnabled {
            notificationFeedback.notificationOccurred(.success)
        }
        if isSoundEnabled {
            let chord: [Double] = [523.25, 659.25, 783.99, 1046.50]
            for (idx, freq) in chord.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.075) { [weak self] in
                    self?.playSynthesizedTone(
                        startFrequency: freq,
                        endFrequency: freq,
                        duration: 0.28,
                        volume: 0.35,
                        harmonicMix: 0.2
                    )
                }
            }
        }
    }

    public func playGameOver() {
        if isHapticsEnabled {
            notificationFeedback.notificationOccurred(.warning)
        }
        if isSoundEnabled {
            let notes: [Double] = [311.13, 277.18, 220.00]
            for (idx, freq) in notes.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(idx) * 0.11) { [weak self] in
                    self?.playSynthesizedTone(
                        startFrequency: freq,
                        endFrequency: freq * 0.94,
                        duration: 0.22,
                        volume: 0.35,
                        harmonicMix: 0.3
                    )
                }
            }
        }
    }

    public func playButtonTap() {
        if isHapticsEnabled {
            lightImpact.impactOccurred(intensity: 0.45)
        }
    }

    private func playSynthesizedTone(
        startFrequency: Double,
        endFrequency: Double,
        duration: Double,
        volume: Float,
        harmonicMix: Double
    ) {
        ensureAudioReady()
        guard isAudioConfigured,
              let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            return
        }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channelData = buffer.floatChannelData?[0] else {
            return
        }

        buffer.frameLength = frameCount
        var phase: Double = 0
        var harmonicPhase: Double = 0

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / Double(frameCount)
            let freq = startFrequency + (endFrequency - startFrequency) * t
            phase += 2.0 * .pi * freq / sampleRate
            harmonicPhase += 2.0 * .pi * (freq * 2.0) / sampleRate

            // Smooth attack (first 6%) + exponential decay envelope
            let attack = min(1.0, t / 0.06)
            let decay = pow(1.0 - t, 1.8)
            let envelope = attack * decay

            let sample = (sin(phase) + harmonicMix * sin(harmonicPhase)) / (1.0 + harmonicMix)
            channelData[frame] = Float(sample * envelope) * volume
        }

        if !playerNode.isPlaying {
            playerNode.play()
        }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }
}
