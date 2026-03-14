import SwiftUI
import AVFoundation

struct VoiceSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var voiceManager = VoiceManager.shared
    @State private var previewPlayer: AVPlayer?
    @State private var playingVoiceId: String?

    private var femaleVoices: [VoiceOption] {
        voiceManager.availableVoices.filter { $0.gender == "female" }
    }

    private var maleVoices: [VoiceOption] {
        voiceManager.availableVoices.filter { $0.gender == "male" }
    }

    private var otherVoices: [VoiceOption] {
        voiceManager.availableVoices.filter { $0.gender != "female" && $0.gender != "male" }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    currentVoiceCard
                        .padding(.top, 8)

                    if !femaleVoices.isEmpty {
                        voiceSection(title: "Female Voices", icon: "person.fill", voices: femaleVoices)
                    }
                    if !maleVoices.isEmpty {
                        voiceSection(title: "Male Voices", icon: "person.fill", voices: maleVoices)
                    }
                    if !otherVoices.isEmpty {
                        voiceSection(title: "Other Voices", icon: "person.fill", voices: otherVoices)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Voice Selection")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            previewPlayer?.pause()
            previewPlayer = nil
        }
    }

    // MARK: - Current Voice Card
    private var currentVoiceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "4F6BED"))
                Text("CURRENT VOICE")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.tertiaryText)
                    .tracking(1)
                Spacer()
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4F6BED").opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: voiceManager.selectedVoice.gender == "female" ? "person.crop.circle.fill" : "person.crop.circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color(hex: "4F6BED"))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(voiceManager.selectedVoice.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)
                    Text("\(voiceManager.selectedVoice.accent) · \(voiceManager.selectedVoice.description)")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondText)
                }

                Spacer()

                previewButton(for: voiceManager.selectedVoice, tint: Color(hex: "4F6BED"))
            }
        }
        .padding(18)
        .background(AppColors.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: "4F6BED").opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color(hex: "4F6BED").opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Voice Section
    private func voiceSection(title: String, icon: String, voices: [VoiceOption]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.tertiaryText)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(AppColors.tertiaryText)
                    .tracking(1)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(voices.enumerated()), id: \.element.id) { index, voice in
                    voiceRow(voice)

                    if index < voices.count - 1 {
                        Divider().background(AppColors.border).padding(.leading, 60)
                    }
                }
            }
            .background(AppColors.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
            )
        }
    }

    // MARK: - Voice Row
    private func voiceRow(_ voice: VoiceOption) -> some View {
        let isSelected = voiceManager.selectedVoiceId == voice.id

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                voiceManager.selectVoice(voice.id)
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color(hex: "4F6BED").opacity(0.15) : AppColors.surface)
                        .frame(width: 40, height: 40)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color(hex: "4F6BED"))
                    } else {
                        Text(String(voice.name.prefix(1)))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.secondText)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(voice.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(isSelected ? Color(hex: "4F6BED") : AppColors.primaryText)
                        Text(voice.accent)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(isSelected ? Color(hex: "4F6BED") : AppColors.tertiaryText)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((isSelected ? Color(hex: "4F6BED") : AppColors.tertiaryText).opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(voice.description)
                        .font(.caption)
                        .foregroundStyle(AppColors.tertiaryText)
                }

                Spacer()

                previewButton(for: voice, tint: isSelected ? Color(hex: "4F6BED") : AppColors.secondText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color(hex: "4F6BED").opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Button
    private func previewButton(for voice: VoiceOption, tint: Color) -> some View {
        Button {
            togglePreview(for: voice)
        } label: {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: playingVoiceId == voice.id ? "stop.fill" : "play.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(tint)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Logic
    private func togglePreview(for voice: VoiceOption) {
        if playingVoiceId == voice.id {
            previewPlayer?.pause()
            previewPlayer = nil
            playingVoiceId = nil
            return
        }

        guard let url = voice.previewURL else { return }

        previewPlayer?.pause()
        playingVoiceId = voice.id

        let item = AVPlayerItem(url: url)
        previewPlayer = AVPlayer(playerItem: item)

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            playingVoiceId = nil
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        previewPlayer?.play()
    }
}

#Preview {
    NavigationStack {
        VoiceSettingsView()
    }
}
