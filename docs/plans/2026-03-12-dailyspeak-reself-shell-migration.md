# DailySpeak ReSelf Shell Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild DailySpeak around the ReSelf-style product shell while preserving the existing learning flow and leaving paid features as a placeholder only.

**Architecture:** Introduce a new app shell layer (`AppState`, auth/inbox splits, root tabs, splash/onboarding/auth gating) and service layer (`APIClient`, auth, notifications, inbox, DailySpeak API service). Keep the current course/practice views as the home experience, then attach them to the new shell instead of the old single-screen entrypoint.

**Tech Stack:** SwiftUI, Foundation, AuthenticationServices, UserNotifications, UIKit, StoreKit review prompt API, URLSession, existing DailySpeak models and resources.

---

## Verified backend reality before implementation

Checked directly in local `manage-man-server` source on March 12, 2026:

- confirmed present:
  - `/auth/register/email/code`
  - `/auth/register/email`
  - `/auth/login`
  - `/auth/oauth/callback`
  - `/auth/refresh`
  - `/auth/logout`
  - `/inbox`
  - `/inbox/read`
  - `/push/register`
  - `/translate/text`
  - `/ws`
- confirmed absent / not found:
  - `/dailyspeak/polish`
  - DailySpeak-specific backend controller/service package

Important constraint:

- `/translate/text` requires APP auth and currently expects `text`, optional `sourceLang`, and `targetLang`
- earlier assumptions such as `sourceLanguage`, `targetLanguage`, `scene`, and `topic` are not backed by current server code

Implementation plans must treat polish/TTS/DailySpeak-specific AI endpoints as missing until backend adds them.

---

### Task 1: Add shell validation that fails before implementation

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1: Write the failing test**

Add assertions for:

- `DailySpeak/App/AppState.swift`
- `DailySpeak/App/AppState+Auth.swift`
- `DailySpeak/App/AppState+Inbox.swift`
- `DailySpeak/App/AppDelegate.swift`
- `DailySpeak/Services/APIClient.swift`
- `DailySpeak/Services/AuthService.swift`
- `DailySpeak/Services/DailySpeakAPIService.swift`
- `DailySpeak/Services/NotificationService.swift`
- `DailySpeak/Services/PushNotificationService.swift`
- `DailySpeak/Views/Shell/SplashAnimationView.swift`
- `DailySpeak/Views/Shell/OnboardingView.swift`
- `DailySpeak/Views/Screens/InitialAuthChoiceView.swift`
- `DailySpeak/Views/Screens/AuthLoginRegisterView.swift`
- `DailySpeak/Views/Screens/NotificationsView.swift`
- `DailySpeak/Views/Screens/PersonalCenterView.swift`
- `DailySpeak/Views/Screens/PaywallPlaceholderView.swift`

Also assert:

- `PracticeAIService.swift` no longer contains `api.openai.com`
- `ContentView.swift` now contains `TabView`

**Step 2: Run test to verify it fails**

Run:

```bash
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```

Expected: FAIL because the production shell files do not exist yet.

### Task 2: Add the new app shell primitives

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState+Auth.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppState+Inbox.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/App/AppDelegate.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Utilities/Constants.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/DailySpeakApp.swift`

**Step 1: Write minimal compile-referencing code from the app entry**

Add `@UIApplicationDelegateAdaptor`, `@StateObject private var appState`, and first-launch flags referenced from new shell files.

**Step 2: Run build to verify it fails**

Run:

```bash
xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

Expected: FAIL on missing shell types.

**Step 3: Write minimal implementation**

Implement:

- persisted auth mode
- initial auth choice completion
- unread count state
- first-launch storage key
- splash/onboarding boot flags

**Step 4: Run build to verify it passes further**

Re-run the same build and confirm the next missing layer is services/views, not app shell primitives.

### Task 3: Add networking and account services

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/APIClient.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/AuthService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/DailySpeakAPIService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/InboxNavigationCoordinator.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/NotificationService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/PushNotificationService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/InAppInboxService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/WebSocketInboxClient.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/UserNotificationDelegate.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/FeedbackService.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/ReviewPromptService.swift`

**Step 1: Write the failing build**

Reference these services from `DailySpeakApp`, `AppState`, and the root shell so the compiler demands them.

**Step 2: Implement minimal services**

Use URLSession-based equivalents where possible and keep the ReSelf response-envelope pattern:

- `{ code, requestId, msg, data }`
- token persistence
- silent inbox refresh failures
- APNs registration hooks
- local reminder scheduling

**Step 3: Re-run build**

Expected: compile proceeds to missing UI shell pieces.

### Task 4: Replace the single root view with shell tabs and gating screens

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/ContentView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Shell/SplashAnimationView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Shell/OnboardingView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/InitialAuthChoiceView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/AuthLoginRegisterView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/NotificationsView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/NotificationSettingsView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/PersonalCenterView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/AppSettingsView.swift`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Screens/PaywallPlaceholderView.swift`

**Step 1: Write minimal tab shell**

Build a 3-tab container:

- Home -> `StageListView`
- Messages -> `NotificationsView`
- Me -> `PersonalCenterView`

**Step 2: Add launch gating**

Keep `SplashAnimationView` and `OnboardingView` DailySpeak-specific, then present `InitialAuthChoiceView` when needed.

**Step 3: Re-run build**

Expected: build passes unless learning screens still depend on the removed old assumptions.

### Task 5: Hook the existing learning experience into the new shell

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/StageListView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/PracticeView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/PracticeAIService.swift`

**Step 1: Write failing shell validation**

Add test assertions that `PracticeAIService.swift` no longer references `api.openai.com` and that `ContentView.swift` contains the new tab shell.

**Step 2: Implement minimal integration**

- Add settings/personal/message access from the new shell, not from lesson pages
- route practice translation through verified backend contract only
- do **not** assume a current `dailyspeak/polish` endpoint exists
- keep the local lesson flow intact

**Step 3: Re-run build**

Expected: build succeeds with the new shell and service routing.

### Task 6: Final verification

**Files:**
- Verify only

**Step 1: Run shell validation**

```bash
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```

Expected: PASS

**Step 2: Run Xcode build**

```bash
xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

Expected: `** BUILD SUCCEEDED **`

**Step 3: Manual checklist**

Confirm the code now contains:

- DailySpeak-specific splash
- DailySpeak-specific onboarding
- guest / Apple / email entry
- messages tab
- personal center tab
- settings / notification settings / paywall placeholder entry
- no direct OpenAI endpoint string in iOS code
