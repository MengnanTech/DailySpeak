import AVFoundation
import Foundation

@MainActor
final class RemoteSpeechPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = RemoteSpeechPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var currentRequestText: String?

    private override init() {}

    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }

    func togglePlayback(text: String, locale: String = "en-US") async throws -> Bool {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return false }

        if let audioPlayer, audioPlayer.isPlaying, currentRequestText == normalized {
            audioPlayer.stop()
            return false
        }

        let data = try await DailySpeakAPIService.shared.synthesizeSpeech(text: normalized, locale: locale)
        let player = try AVAudioPlayer(data: data)
        player.delegate = self
        player.prepareToPlay()
        currentRequestText = normalized
        audioPlayer = player
        player.play()
        return true
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentRequestText = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer = nil
        currentRequestText = nil
    }
}
