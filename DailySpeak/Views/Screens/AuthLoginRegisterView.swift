import SwiftUI
import AuthenticationServices
import Combine

struct AuthLoginRegisterView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case login
        case register

        var id: String { rawValue }

        var title: String {
            switch self {
            case .login:
                return "登录"
            case .register:
                return "注册"
            }
        }
    }

    enum Step {
        case email
        case verify
        case password
    }

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode
    @State private var step: Step = .email
    @State private var email = ""
    @State private var password = ""
    @State private var verificationCode = ""
    @State private var errorMessage: String?
    @State private var isSubmitting = false
    @State private var isSendingCode = false
    @State private var codeSendUntil: Date?
    @State private var now = Date()
    @State private var hasAutoSentCode = false

    init(initialMode: Mode) {
        _mode = State(initialValue: initialMode)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedPassword: String {
        password.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedVerificationCode: String {
        verificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var codeCooldownRemaining: Int {
        guard let until = codeSendUntil else { return 0 }
        return max(0, Int(until.timeIntervalSince(now)))
    }

    private var isEmailValid: Bool {
        trimmedEmail.contains("@") && trimmedEmail.contains(".")
    }

    var body: some View {
        ZStack {
            Color.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    switch step {
                    case .email:
                        emailStepView
                    case .verify:
                        verifyStepView
                    case .password:
                        passwordStepView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .alert("操作失败", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("好的", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "请稍后重试。")
        }
        .onAppear {
            appState.resetAppleSignInProgress()
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private var emailStepView: some View {
        Group {
            VStack(spacing: 10) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("登录 DailySpeak")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("输入邮箱开始登录或注册")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)

            VStack(spacing: 12) {
                SignInWithAppleButton(.signIn, onRequest: configureAppleLoginRequest, onCompletion: handleAppleLoginCompletion)
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(appState.isAppleSignInInProgress)

                HStack(spacing: 10) {
                    Rectangle()
                        .fill(Color.textMuted.opacity(0.35))
                        .frame(height: 1)
                    Text("或者使用邮箱")
                        .font(.caption)
                        .foregroundColor(.textMuted)
                    Rectangle()
                        .fill(Color.textMuted.opacity(0.35))
                        .frame(height: 1)
                }

                Picker("", selection: $mode) {
                    ForEach(Mode.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                TextField("输入邮箱", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.backgroundCard)
                    )

                Button(action: handleEmailContinue) {
                    Text("下一步")
                        .font(.headline)
                        .foregroundColor(isEmailValid ? .textPrimary : .textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isEmailValid ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isEmailValid)

                privacyAgreementFooter
            }
        }
    }

    private var verifyStepView: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text("输入验证码")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)

                Text("验证码已发送到 \(trimmedEmail)")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)

            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    TextField("验证码", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundCard)
                        )

                    Button(action: sendRegisterCode) {
                        Text(codeCooldownRemaining > 0 ? "\(codeCooldownRemaining)s" : (isSendingCode ? "发送中" : "重发"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primaryCyan)
                            .frame(width: 86, height: 50)
                    }
                    .buttonStyle(.plain)
                    .disabled(codeCooldownRemaining > 0 || isSendingCode)
                }

                Button(action: handleVerifyContinue) {
                    let canVerify = !trimmedVerificationCode.isEmpty && !isSubmitting
                    Text(isSubmitting ? "提交中" : "完成注册")
                        .font(.headline)
                        .foregroundColor(canVerify ? .textPrimary : .textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canVerify ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(trimmedVerificationCode.isEmpty || isSubmitting)

                Button(action: goBack) {
                    Text("上一步")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .onAppear {
            if !hasAutoSentCode {
                hasAutoSentCode = true
                sendRegisterCode()
            }
        }
    }

    private var passwordStepView: some View {
        VStack(spacing: 22) {
            VStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.textPrimary)

                Text(mode == .login ? "输入密码" : "设置密码")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.textPrimary)
            }
            .padding(.top, 16)

            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("邮箱")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    HStack {
                        Text(trimmedEmail)
                            .font(.body)
                            .foregroundColor(.textPrimary)

                        Spacer()

                        Button("修改") {
                            goBackToEmail()
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primaryCyan)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.backgroundCard)
                    )
                }

                SecureField("输入密码", text: $password)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 14)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.backgroundCard)
                    )

                Button(action: handlePasswordContinue) {
                    let canSubmit = !trimmedPassword.isEmpty && !isSubmitting
                    Text(passwordButtonTitle)
                        .font(.headline)
                        .foregroundColor(canSubmit ? .textPrimary : .textMuted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSubmit ? Color.backgroundSecondary : Color.backgroundSecondary.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(trimmedPassword.isEmpty || isSubmitting)

                Button(action: goBack) {
                    Text("上一步")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
    }

    private func handleEmailContinue() {
        guard isEmailValid else { return }
        withAnimation {
            step = .password
        }
    }

    private func handleVerifyContinue() {
        guard !trimmedVerificationCode.isEmpty else { return }
        handleSubmit()
    }

    private func goBack() {
        withAnimation {
            switch step {
            case .email:
                break
            case .verify:
                step = .password
            case .password:
                step = .email
            }
        }
    }

    private func goBackToEmail() {
        withAnimation {
            step = .email
        }
    }

    private func configureAppleLoginRequest(_ request: ASAuthorizationAppleIDRequest) {
        appState.configureAppleLoginRequest(request)
    }

    private func handleAppleLoginCompletion(_ result: Result<ASAuthorization, Error>) {
        Task { @MainActor in
            switch await appState.handleAppleSignIn(result: result) {
            case .success:
                dismiss()
            case .cancelled:
                break
            case .failure(let message):
                errorMessage = message
            }
        }
    }

    private func handleSubmit() {
        let currentEmail = trimmedEmail
        let currentPassword = trimmedPassword
        let currentCode = trimmedVerificationCode
        guard !isSubmitting else { return }

        isSubmitting = true
        Task { @MainActor in
            defer { isSubmitting = false }
            do {
                if mode == .login {
                    try await appState.loginWithEmail(email: currentEmail, password: currentPassword)
                } else {
                    try await appState.registerWithEmail(email: currentEmail, password: currentPassword, verificationCode: currentCode)
                }
                dismiss()
            } catch let APIError.api(_, message) {
                errorMessage = message ?? "请稍后重试。"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handlePasswordContinue() {
        guard !trimmedPassword.isEmpty else { return }
        if mode == .login {
            handleSubmit()
        } else {
            withAnimation {
                step = .verify
            }
        }
    }

    private var passwordButtonTitle: String {
        if mode == .login && isSubmitting {
            return "登录中"
        }
        return "下一步"
    }

    private func sendRegisterCode() {
        let currentEmail = trimmedEmail
        guard currentEmail.contains("@"), currentEmail.contains(".") else { return }
        guard codeCooldownRemaining == 0 else { return }
        guard !isSendingCode else { return }

        isSendingCode = true
        now = Date()
        codeSendUntil = Date().addingTimeInterval(60)

        Task { @MainActor in
            do {
                try await AuthService.shared.sendEmailRegisterCode(email: currentEmail)
                isSendingCode = false
            } catch let APIError.api(_, message) {
                isSendingCode = false
                codeSendUntil = nil
                errorMessage = message ?? "验证码发送失败，请稍后重试。"
            } catch {
                isSendingCode = false
                codeSendUntil = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    private var privacyAgreementFooter: some View {
        Group {
            if let privacyURL = URL(string: Constants.privacyPolicyURL),
               let termsURL = URL(string: Constants.termsOfServiceURL) {
                Text("继续即表示你同意 DailySpeak 的相关协议")
                    .font(.caption)
                    .foregroundColor(.textMuted)
                HStack(spacing: 6) {
                    Link("隐私政策", destination: privacyURL)
                    Text("和")
                    Link("服务条款", destination: termsURL)
                }
                .font(.caption.weight(.semibold))
                .foregroundColor(.textMuted)
            } else {
                Text("继续即表示你同意相关协议")
                    .font(.caption)
                    .foregroundColor(.textMuted)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.top, 4)
    }
}

#Preview {
    NavigationStack {
        AuthLoginRegisterView(initialMode: .login)
            .environmentObject(AppState())
    }
}
