import SwiftUI

struct AuthLoginRegisterView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var isRegisterMode = false
    @State private var isSubmitting = false
    @State private var message: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(isRegisterMode ? "Create account" : "Welcome back")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .padding(14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))

                    SecureField("Password", text: $password)
                        .padding(14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))

                    if isRegisterMode {
                        HStack(spacing: 10) {
                            TextField("Verification code", text: $verificationCode)
                                .textInputAutocapitalization(.never)
                                .padding(14)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))

                            Button("Send") {
                                Task {
                                    do {
                                        try await AuthService.shared.sendEmailRegisterCode(email: email)
                                        message = "Verification code sent."
                                    } catch {
                                        message = error.localizedDescription
                                    }
                                }
                            }
                            .font(.subheadline.bold())
                        }
                    }

                    Button(action: submit) {
                        HStack {
                            Spacer()
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isRegisterMode ? "Register" : "Sign In")
                                    .font(.headline.bold())
                            }
                            Spacer()
                        }
                        .frame(height: 52)
                        .background(Color(hex: "1A1714"), in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmitting)

                    Button(isRegisterMode ? "Already have an account?" : "Create an account") {
                        isRegisterMode.toggle()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(hex: "4F6BED"))

                    if let message {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(AppColors.secondText)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func submit() {
        isSubmitting = true
        message = nil
        Task {
            do {
                if isRegisterMode {
                    try await appState.registerWithEmail(email: email, password: password, verificationCode: verificationCode)
                } else {
                    try await appState.loginWithEmail(email: email, password: password)
                }
                dismiss()
            } catch {
                message = error.localizedDescription
            }
            isSubmitting = false
        }
    }
}
