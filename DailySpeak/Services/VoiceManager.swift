import Foundation
import SwiftUI

struct VoiceOption: Identifiable, Equatable {
    let id: String          // ElevenLabs voice_id
    let name: String
    let gender: String
    let accent: String
    let description: String
    let previewURL: URL?
}

@Observable
final class VoiceManager {
    static let shared = VoiceManager()

    private let selectedVoiceKey = "dailyspeak.tts.selectedVoiceId"
    private let defaults = UserDefaults.standard

    // Default premade voice: Sarah (female, american, professional)
    static let defaultVoiceId = "EXAVITQu4vr4xnSDxMaL"

    // Built-in premade voices (available on ElevenLabs free tier)
    let availableVoices: [VoiceOption] = [
        VoiceOption(id: "EXAVITQu4vr4xnSDxMaL", name: "Sarah", gender: "female", accent: "American", description: "Mature, Reassuring, Confident", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/EXAVITQu4vr4xnSDxMaL/01a3e33c-6e99-4ee7-8543-ff2216a32186.mp3")),
        VoiceOption(id: "XrExE9yKIg1WjnnlVkGX", name: "Matilda", gender: "female", accent: "American", description: "Knowledgable, Professional", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/XrExE9yKIg1WjnnlVkGX/6e5c9e67-c01f-4a81-a670-a4cee181b5c4.mp3")),
        VoiceOption(id: "Xb7hH8MSUJpSbSDYk0k2", name: "Alice", gender: "female", accent: "British", description: "Clear, Engaging Educator", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/Xb7hH8MSUJpSbSDYk0k2/d10f7534-11f6-41fe-a012-2de1e482d336.mp3")),
        VoiceOption(id: "pFZP5JQG7iQjIQuC4Bku", name: "Lily", gender: "female", accent: "British", description: "Velvety Actress", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/pFZP5JQG7iQjIQuC4Bku/89b68b35-b3dd-4348-a84a-a3c13a3c2b30.mp3")),
        VoiceOption(id: "cgSgspJ2msm6clMCkdW9", name: "Jessica", gender: "female", accent: "American", description: "Playful, Bright, Warm", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/cgSgspJ2msm6clMCkdW9/39e2cabc-391a-4382-8a5e-bb9a6ee29edc.mp3")),
        VoiceOption(id: "FGY2WhTYpPnrIDTdsKH5", name: "Laura", gender: "female", accent: "American", description: "Enthusiast, Quirky Attitude", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/FGY2WhTYpPnrIDTdsKH5/1daeadbc-1b46-4bae-94e4-1e6b0e0d40f6.mp3")),
        VoiceOption(id: "hpp4J3VqNfWAUOO0d1Us", name: "Bella", gender: "female", accent: "American", description: "Professional, Bright, Warm", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/hpp4J3VqNfWAUOO0d1Us/5bb774b0-3575-426b-b7a0-be23e3883af5.mp3")),
        VoiceOption(id: "CwhRBWXzGAHq8TQ4Fs17", name: "Roger", gender: "male", accent: "American", description: "Laid-Back, Casual, Resonant", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/CwhRBWXzGAHq8TQ4Fs17/58ee3ff5-f6f2-4628-93b8-e38eb31806b0.mp3")),
        VoiceOption(id: "JBFqnCBsd6RMkjVDRZzb", name: "George", gender: "male", accent: "British", description: "Warm, Captivating Storyteller", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/JBFqnCBsd6RMkjVDRZzb/e6206d1a-0721-4787-aafb-06a6e705cac5.mp3")),
        VoiceOption(id: "cjVigY5qzO86Huf0OWal", name: "Eric", gender: "male", accent: "American", description: "Smooth, Trustworthy", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/cjVigY5qzO86Huf0OWal/0dcc5e1e-0f67-4aff-87bf-a5ed1e5a05f0.mp3")),
        VoiceOption(id: "onwK4e9ZLuTAKqWW03F9", name: "Daniel", gender: "male", accent: "British", description: "Steady Broadcaster", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/onwK4e9ZLuTAKqWW03F9/3bcb1fbb-7ab2-41c0-971e-3b0d28a107f9.mp3")),
        VoiceOption(id: "nPczCjzI2devNBz1zQrb", name: "Brian", gender: "male", accent: "American", description: "Deep, Resonant and Comforting", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/nPczCjzI2devNBz1zQrb/2dd3e72c-4fd3-42f1-93ea-abc5d4e5aa1d.mp3")),
        VoiceOption(id: "IKne3meq5aSn9XLyUdCD", name: "Charlie", gender: "male", accent: "Australian", description: "Deep, Confident, Energetic", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/IKne3meq5aSn9XLyUdCD/102de6f2-22ed-43e0-a1f1-111fa75c5481.mp3")),
        VoiceOption(id: "SAz9YHcvj6GT2YYXdXww", name: "River", gender: "neutral", accent: "American", description: "Relaxed, Neutral, Informative", previewURL: URL(string: "https://storage.googleapis.com/eleven-public-prod/premade/voices/SAz9YHcvj6GT2YYXdXww/e9418838-2b6d-41ee-9a4f-1431be3e6096.mp3")),
    ]

    private(set) var selectedVoiceId: String

    private init() {
        self.selectedVoiceId = UserDefaults.standard.string(forKey: "dailyspeak.tts.selectedVoiceId") ?? VoiceManager.defaultVoiceId
    }

    var selectedVoice: VoiceOption {
        availableVoices.first { $0.id == selectedVoiceId } ?? availableVoices[0]
    }

    func selectVoice(_ voiceId: String) {
        guard voiceId != selectedVoiceId else { return }
        selectedVoiceId = voiceId
        defaults.set(voiceId, forKey: selectedVoiceKey)
        Task { @MainActor in
            EnglishSpeechPlayer.shared.clearAudioCache()
        }
    }
}
