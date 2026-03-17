import SwiftUI
import AuthenticationServices

struct InitialAuthChoiceView: View {
    @EnvironmentObject var appState: AppState

    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundDark.ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 54, weight: .semibold))
                            .foregroundStyle(LinearGradient.primaryGradient)

                        Text("Choose how to get started")
                            .font(.title3.weight(.bold))
                            .foregroundColor(.textPrimary)

                        Text("Start as a guest, or sign in with Apple or email.")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    VStack(spacing: 14) {
                        SignInWithAppleButton(.signIn, onRequest: configureAppleLoginRequest, onCompletion: handleAppleLoginCompletion)
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .disabled(appState.isAppleSignInInProgress)

                        NavigationLink {
                            AuthLoginRegisterView(initialMode: .login)
                                .environmentObject(appState)
                        } label: {
                            Text("Email Sign In / Register")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.backgroundSecondary)
                                )
                        }
                        .buttonStyle(.plain)

                        Button(action: continueAsGuest) {
                            Text("Continue as Guest")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textMuted.opacity(0.45), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
        }
        .alert("Sign In Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? String(localized: "Please try again later."))
        }
        .onAppear {
            appState.resetAppleSignInProgress()
        }
    }

    private func continueAsGuest() {
        appState.completeInitialAuthChoiceAsGuest()
    }

    private func configureAppleLoginRequest(_ request: ASAuthorizationAppleIDRequest) {
        appState.configureAppleLoginRequest(request)
    }

    private func handleAppleLoginCompletion(_ result: Result<ASAuthorization, Error>) {
        Task { @MainActor in
            switch await appState.handleAppleSignIn(result: result) {
            case .success:
                break
            case .cancelled:
                break
            case .failure(let message):
                errorMessage = message
            }
        }
    }
}

#Preview {
    InitialAuthChoiceView()
        .environmentObject(AppState())
}
