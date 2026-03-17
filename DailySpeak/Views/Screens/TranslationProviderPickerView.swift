import SwiftUI

struct TranslationProviderPickerView: View {
    @Binding var selection: String

    private var options: [(id: String, name: String, description: String)] {
        [
            ("auto", "Auto", String(localized: "Default: DeepL machine translation")),
            ("deepl", "DeepL", String(localized: "High-quality machine translation")),
            ("deepseek", "DeepSeek AI", String(localized: "AI large model translation, more natural")),
        ]
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(options, id: \.id) { option in
                        Button {
                            selection = option.id
                        } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(option.name)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(AppColors.primaryText)
                                    Text(option.description)
                                        .font(.caption)
                                        .foregroundStyle(AppColors.tertiaryText)
                                }

                                Spacer()

                                if selection == option.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color(hex: "0EA5E9"))
                                } else {
                                    Circle()
                                        .strokeBorder(AppColors.border, lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                }
                            }
                            .padding(16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if option.id != options.last?.id {
                            Divider().background(AppColors.border).padding(.leading, 16)
                        }
                    }
                }
                .background(AppColors.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppColors.border.opacity(0.5), lineWidth: 0.5)
                )
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .navigationTitle("Translation Engine")
        .navigationBarTitleDisplayMode(.inline)
    }
}
