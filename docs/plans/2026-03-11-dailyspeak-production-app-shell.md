# DailySpeak Production App Shell Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Turn DailySpeak into a release-grade app with backend auth, server-backed AI/audio flow, onboarding, settings, notifications, feedback, review prompts, and legal shell while preserving the existing local lesson experience.

**Architecture:** Reuse the ReSelf shell pattern on iOS (`AppState`, `APIClient`, auth gating, settings modules) and extend `manage-man-server` only where DailySpeak needs missing product-specific endpoints. Keep local JSON course content and local progress as the study backbone, while moving translation, polish, TTS, and audio upload behind the server.

**Tech Stack:** SwiftUI, Foundation, AuthenticationServices, AVFoundation, Speech, UserDefaults, StoreKit review prompt API, Java Spring Boot, MongoDB metadata, Cloudflare R2, ElevenLabs, existing manage-man auth envelope.

---

### Task 1: Add failing validation for production shell presence

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1:** Add failing checks that assert the app now contains:
- an `AppState` file
- an `APIClient` file
- a settings screen
- an onboarding screen
- a notification service
- an auth screen or auth choice screen
- a DailySpeak API service that does not call OpenAI directly

**Step 2:** Add failing checks that assert:
- `PracticeAIService.swift` no longer contains `api.openai.com`
- `PracticeView.swift` no longer uses `AVSpeechSynthesizer` as the primary TTS path

**Step 3:** Run:
```bash
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```

Expected: FAIL because the production shell files and server-backed AI path do not exist yet.

### Task 2: Introduce iOS app shell state and API client

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState+Auth.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/APIClient.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/AuthService.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/DailySpeakApp.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/ContentView.swift`

**Step 1:** Write the minimal shell state and compile-failing references from the app entry.

**Step 2:** Verify the build fails for missing implementations.

**Step 3:** Add the minimal working `APIClient` and auth state persistence:
- `manage-man-server` style result envelope parsing
- access token persistence
- guest / apple / email auth mode storage

**Step 4:** Update the app entry to inject `AppState` alongside the existing `ProgressManager`.

**Step 5:** Re-run build until the app compiles with the new shell layer.

### Task 3: Add onboarding and auth choice flow

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/OnboardingView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/AuthChoiceView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/AuthLoginRegisterView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/ContentView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState+Auth.swift`

**Step 1:** Write failing structure checks in the shell script for onboarding/auth files.

**Step 2:** Build minimal views that gate launch:
- onboarding on first launch
- auth choice after onboarding
- guest path allowed

**Step 3:** Implement email login/register and Apple Sign In wiring using the existing `manage-man-server` auth endpoints.

**Step 4:** Verify:
- guest can enter app
- logged-in mode persists across relaunch

### Task 4: Add settings, legal, feedback, and review prompt shell

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/SettingsView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/FeedbackService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/ReviewPromptService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Utilities/Constants.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/StageListView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/ContentView.swift`

**Step 1:** Add a settings entry from the main app flow.

**Step 2:** Implement a minimal settings screen with:
- account summary
- sign in / sign out
- privacy policy
- terms of service
- about/version
- feedback
- rate app
- reset local progress

**Step 3:** Add feedback payload generation with device/app diagnostics.

**Step 4:** Add review prompt trigger points from learning milestones.

### Task 5: Add notification settings and local reminder flow

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/NotificationService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/NotificationSettingsView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/SettingsView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/DailySpeakApp.swift`

**Step 1:** Write failing checks for notification service/settings presence.

**Step 2:** Implement local daily reminder scheduling with:
- enable/disable
- hour/minute persistence
- permission request on demand

**Step 3:** Link notification settings from Settings.

**Step 4:** Verify the app still runs even if notification permission is denied.

### Task 6: Replace direct OpenAI usage with server-backed learning APIs

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/PracticeAIService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/DailySpeakAPIService.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/PracticeView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`

**Step 1:** Remove direct `api.openai.com` dependency from iOS.

**Step 2:** Route translation calls through `manage-man-server /translate/text`.

**Step 3:** Route polish calls through a DailySpeak-specific backend endpoint.

**Step 4:** Update error handling so auth failures and server envelope failures surface cleanly in UI.

### Task 7: Add server-backed TTS playback and audio upload on iOS

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/AudioUploadService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/TTSPlaybackService.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/PracticeView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/SpeechInputManager.swift`

**Step 1:** Add iOS-side upload and playback service abstractions.

**Step 2:** Keep local speech recognition for transcript capture.

**Step 3:** Add local recording file generation suitable for upload (`m4a`).

**Step 4:** Replace local synthesizer-first behavior with server audio playback.

### Task 8: Extend manage-man-server for DailySpeak polish and TTS product endpoints

**Files:**
- Create: `/Users/levi/project/Java/manage-man-server/web/src/main/java/com/manage/man/controller/dailyspeak/DailySpeakController.java`
- Create: `/Users/levi/project/Java/manage-man-server/service/src/main/java/com/manage/man/domain/dailyspeak/service/DailySpeakService.java`
- Create: `/Users/levi/project/Java/manage-man-server/service/src/main/java/com/manage/man/domain/dailyspeak/service/impl/DailySpeakServiceImpl.java`
- Create request/response DTOs under `/Users/levi/project/Java/manage-man-server/service/src/main/java/com/manage/man/domain/dailyspeak/dto/`
- Modify existing config/client files only if needed for provider wiring

**Step 1:** Add failing server compile references for new DailySpeak-specific endpoints.

**Step 2:** Implement:
- polish endpoint
- TTS endpoint that returns a playable URL or media payload metadata

**Step 3:** Reuse existing ElevenLabs and file storage facilities instead of creating a separate pipeline.

**Step 4:** Keep auth guarded with `@Auth(client = AuthClient.APP)`.

### Task 9: Add audio upload contract in manage-man-server for DailySpeak recordings

**Files:**
- Modify or extend: `/Users/levi/project/Java/manage-man-server/web/src/main/java/com/manage/man/controller/file/FileUploadController.java`
- Create DailySpeak-specific request/response DTOs if needed
- Create metadata persistence classes only if recording metadata is stored now

**Step 1:** Decide whether to reuse `/api/file/r2/upload` directly or add a DailySpeak-specific wrapped endpoint.

**Step 2:** Prefer a DailySpeak-specific endpoint if extra metadata is required:
- task id
- audio type
- duration

**Step 3:** Return a stable response shape that the iOS app can consume directly.

### Task 10: Add release metadata and permission strings

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Info.plist` or project plist source if present
- Create/modify localization and plist strings resources if needed

**Step 1:** Ensure permission descriptions exist for:
- microphone
- speech recognition
- notifications if needed

**Step 2:** Ensure privacy/terms URLs are configurable via constants.

### Task 11: Verify end-to-end

**Files:**
- Verify only

**Step 1:** Run iOS shell validation:
```bash
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```

Expected: PASS

**Step 2:** Build DailySpeak:
```bash
xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

Expected: `** BUILD SUCCEEDED **`

**Step 3:** Compile backend:
```bash
cd /Users/levi/project/Java/manage-man-server
gradle :service:compileJava :web:compileJava
```

Expected: BUILD SUCCESSFUL

**Step 4:** Smoke-check backend contracts as needed with existing HTTP client files or curl.

### Task 12: Final integration review

**Files:**
- Review only

**Step 1:** Confirm the app can:
- launch through onboarding/auth shell
- enter guest mode
- log in via Apple or email
- call backend translation
- call backend polish
- play backend TTS
- upload user audio
- open settings and legal links

**Step 2:** Document any remaining deferred items explicitly:
- server-side transcription
- cloud progress sync
- subscription/paywall
- APNs push
