import AVFoundation

final class PaperTearSound {
    static let shared = PaperTearSound()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format: AVAudioFormat

    private init() {
        let sampleRate = 44100.0
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func play() {
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Failed to restart audio engine: \(error)")
                return
            }
        }

        let duration = 0.18
        let frameCount = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        if let channel = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) {
                let t = Double(i) / Double(frameCount)
                let attack = min(t * 16.0, 1.0)
                let decay = max(1.0 - t * 1.2, 0.0)
                let envelope = attack * decay
                let noise = Float.random(in: -1.0...1.0)
                channel[i] = noise * Float(envelope) * 0.35
            }
        }

        player.play()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }
}
