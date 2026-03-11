import SwiftUI
import AuthenticationServices

struct AuthChoiceView: View {
    @Environment(AppState.self) private var appState
    @State private var showEmailAuth = false
    @State private var appleError: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 18) {
                    Spacer()

                    Text("Choose how to continue")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Guest mode keeps learning local. Sign in unlocks server AI and audio upload.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondText)

                    SignInWithAppleButton(.continue) { request in
                        appState.configureAppleLoginRequest(request)
                    } onCompletion: { result in
                        Task {
                            let outcome = await appState.handleAppleSignIn(result: result)
                            if case let .failure(message) = outcome {
                                appleError = message
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button {
                        showEmailAuth = true
                    } label: {
                        Text("Continue with Email")
                            .font(.headline.bold())
                            .foregroundStyle(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        appState.completeInitialAuthChoiceAsGuest()
                    } label: {
                        Text("Continue as Guest")
                            .font(.subheadline.bold())
                            .foregroundStyle(AppColors.secondText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(24)
            }
            .navigationDestination(isPresented: $showEmailAuth) {
                AuthLoginRegisterView()
            }
            .alert("Apple Sign In Failed", isPresented: Binding(get: { appleError != nil }, set: { if !$0 { appleError = nil } })) {
                Button("OK", role: .cancel) {
                    appleError = nil
                }
            } message: {
                Text(appleError ?? "")
            }
        }
    }
}
