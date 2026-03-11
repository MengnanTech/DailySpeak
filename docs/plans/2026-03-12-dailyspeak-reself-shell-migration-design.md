# DailySpeak ReSelf Shell Migration Design

**Context**

`DailySpeak` is currently a course prototype with local content, local progress, and direct practice helpers. It lacks the production shell already present in `ReSelf`: launch gating, onboarding, auth/guest split, notification settings, inbox, personal center, and unified API wiring.

The user asked to:

- modify directly on `main`
- copy the current `ReSelf` framework into `DailySpeak`
- keep the existing learning flow
- customize the splash animation and onboarding for `DailySpeak`
- move networking to the front of the architecture
- add API push, notification permission flow, login/guest center, personal page, messages
- keep a paywall entry and placeholder page, but do not implement paid purchase logic this round

**Decision**

Adopt the `ReSelf` shell architecture but trim it to DailySpeak's actual scope:

- keep `AppState + split extensions + API client + auth service + inbox/push stack`
- keep a tab-shell structure with home, messages, and personal center
- keep guest, Apple, and email auth modes
- keep local notifications and APNs registration plumbing
- keep a paywall entry point and placeholder page only
- replace `ReSelf` splash/onboarding visuals with `DailySpeak`-specific versions
- preserve `DailySpeak`'s current lesson/stage/task/practice views as the learning backbone

## Architecture

### App shell

Add a new app shell under `DailySpeak/App/`:

- `DailySpeakApp.swift`
- `AppDelegate.swift`
- `AppState.swift`
- `AppState+Auth.swift`
- `AppState+Inbox.swift`

This layer owns:

- first-launch gating
- splash visibility
- onboarding completion
- auth mode and persisted user identity
- unread message count
- top-level tab selection

### Services

Add unified service objects under `DailySpeak/Services/`:

- `APIClient`
- `AuthService`
- `DailySpeakAPIService`
- `NotificationService`
- `PushNotificationService`
- `InAppInboxService`
- `WebSocketInboxClient`
- `UserNotificationDelegate`
- `InboxNavigationCoordinator`
- `FeedbackService`
- `ReviewPromptService`

This puts networking before feature UI. Screens call services; services talk to backend and messaging channels.

### Views

Add shell views under `DailySpeak/Views/Shell/` and `DailySpeak/Views/Screens/`:

- custom `SplashAnimationView`
- custom `OnboardingView`
- `InitialAuthChoiceView`
- `AuthLoginRegisterView`
- `NotificationsView`
- `NotificationSettingsView`
- `PersonalCenterView`
- `AppSettingsView`
- `PaywallPlaceholderView`

The home tab will continue to use the existing stage/task/learning views.

### Learning domain

Keep the existing content stack:

- `CourseData`
- `LessonRepository`
- `ProgressManager`
- `StageListView`
- `TaskOverviewView`
- `LearningFlowView`
- `PracticeView`

The learning domain remains locally usable in guest mode.

## User flow

1. App launch shows a DailySpeak-specific splash animation.
2. First launch enters onboarding.
3. After onboarding, user chooses:
   - Continue with Apple
   - Continue with email
   - Continue as guest
4. Main app opens to a 3-tab shell:
   - Home
   - Messages
   - Me
5. Me tab exposes settings, auth status, notification settings, legal links, feedback, and paywall placeholder.

## Paywall scope

This pass does not implement real subscriptions.

It only keeps:

- paywall entry from personal center/settings
- a branded paywall placeholder screen
- upgrade messaging and legal links

No StoreKit product loading, purchase flow, or restore flow will be added.

## Push and inbox scope

This pass adds the same implementation style as `ReSelf`:

- local reminder permission and scheduling
- APNs registration hooks
- remote push payload ingestion into local inbox storage
- backend in-app inbox pull
- websocket inbox updates

If backend endpoints are not fully available yet, the services must fail silently and not block the app shell.

## AI/network scope

`PracticeAIService` should stop talking directly to OpenAI.

Instead:

- `DailySpeakAPIService` becomes the client entrypoint for translation/polish/TTS-style operations
- `PracticeView` and related screens call this service
- auth errors and server-envelope failures surface as user-friendly messages

If a backend endpoint is still missing, the client implementation should stay structured for backend routing rather than preserve direct OpenAI coupling.

## Verified Backend Contract Status

The following items were re-checked directly against the current local `manage-man-server` source on March 12, 2026.

### Verified existing endpoints

- `POST /auth/register/email/code`
- `POST /auth/register/email`
- `POST /auth/login`
- `POST /auth/oauth/callback`
- `POST /auth/refresh`
- `POST /auth/logout`
- `GET /inbox`
- `POST /inbox/read`
- `POST /push/register`
- WebSocket endpoint: `/ws`
- `POST /translate/text`

### Verified auth requirements

- `/auth/register/email/code`, `/auth/register/email`, `/auth/login`, `/auth/oauth/callback` are public (`@NoAuth`)
- `/auth/refresh` and `/auth/logout` require `AuthClient.APP`
- `/inbox` requires `AuthClient.APP`
- `/translate/text` requires `AuthClient.APP`
- `/push/register` currently does **not** enforce `@Auth(client = AuthClient.APP)` in controller code; it accepts nullable `AuthUser`

### Verified translation request/response shape

`POST /translate/text` currently expects:

- request:
  - `text`
  - optional `sourceLang`
  - required `targetLang`
- response data:
  - `translatedText`
  - `detectedSourceLang`
  - `provider`

This means prior client assumptions like `sourceLanguage`, `targetLanguage`, `scene`, and `topic` are **not verified** by the current backend contract.

### Not verified / not present in current backend source

- `POST /dailyspeak/polish`
- any dedicated DailySpeak controller/package under `controller/dailyspeak`
- any dedicated DailySpeak TTS endpoint
- any dedicated DailySpeak audio-upload metadata endpoint

These must be treated as future backend work, not current app assumptions.

## Verification

Verification for this migration must include:

- shell validation script updated to assert the new architecture exists
- Xcode build for `DailySpeak`
- confirmation that the old direct OpenAI endpoint string is removed from iOS code
