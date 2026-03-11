# DailySpeak Production App Shell Design

**Context**

DailySpeak currently has a working local learning flow:

- staged JSON course content
- stage list and task navigation
- lesson overview and learning flow
- local progress state
- local speech recognition
- direct OpenAI requests for translation/polish
- local `AVSpeechSynthesizer` for TTS

This is enough for internal preview, but not enough for a release-grade app. There is no formal auth shell, no settings surface, no legal/support scaffolding, no server-backed AI chain, and no clear separation between local learning state and server-powered features.

At the same time, `manage-man-server` already provides the core backend building blocks needed for a real product:

- user auth
- translation API
- file upload to Cloudflare R2
- ElevenLabs-based TTS service

The ReSelf iOS app in the same workspace already demonstrates a production-ready app shell for:

- Apple / email / guest auth
- centralized API client
- onboarding
- settings / feedback / review prompt
- notification settings
- legal/compliance entry points

**Goal**

Upgrade DailySpeak from a local prototype into a release-grade iOS app with a complete app shell and a server-connected AI chain, while preserving the existing course flow and local lesson data.

**Product Direction**

DailySpeak should become:

- a real iOS app with onboarding, auth, settings, feedback, notifications, legal links, and review prompts
- a locally usable learning tool even in guest mode
- a server-backed app for AI translation, polishing, TTS, and audio upload when the user is authenticated

It should not become:

- a server-first content app that depends on cloud lesson delivery to open
- a postcard-style visual concept app
- a one-off architecture unrelated to ReSelf and `manage-man-server`

## Architecture

DailySpeak will be organized into four runtime layers.

### 1. App Shell

Add a new global state model, aligned with the ReSelf pattern:

- `AppState`
- `AppState+Auth`
- centralized `APIClient`
- backend auth services

This layer owns:

- launch gating
- onboarding completion state
- auth mode (`guest`, `apple`, `email`)
- backend token persistence
- profile summary needed by Settings

### 2. Learning Domain

The existing local course and progress architecture stays in place:

- `CourseData`
- `LessonRepository`
- local JSON lesson bundle
- `ProgressManager`
- current stage/task navigation

This remains the app's learning backbone so DailySpeak still works when the server is unavailable.

### 3. Server-Powered AI

All AI/networked learning helpers should move behind `manage-man-server`.

- translation: use existing `/translate/text`
- polish/rewrite: add a DailySpeak-specific backend endpoint
- TTS: use backend ElevenLabs integration
- audio upload: use backend R2 upload flow

The iOS app should stop talking directly to OpenAI and should stop treating local system TTS as the primary pronunciation path.

### 4. Release Shell

Add the missing product surfaces required for App Store readiness:

- onboarding
- auth choice and login/register
- settings
- notification settings
- feedback entry
- review prompt policy
- privacy / terms / about

## Auth Strategy

DailySpeak should support:

- Apple login
- email login/register
- guest mode

Recommended behavior:

- onboarding first
- auth choice immediately after onboarding
- guest mode allowed
- server-backed features require backend token

Guest mode is intentionally not blocked because the app's core lesson flow is local. However, the upgrade path should be visible whenever the user wants cloud-backed features.

## AI / Audio Chain

### Translation

Use `manage-man-server /translate/text` instead of direct OpenAI access.

Verified later against local backend source:

- endpoint exists
- it requires APP auth
- request fields are `text`, optional `sourceLang`, required `targetLang`
- request fields like `sourceLanguage`, `targetLanguage`, `scene`, `topic` were only assumptions and are not part of the current contract

### Polish / Rewrite

Add a backend endpoint for turning user input into concise, natural spoken English. This is a DailySpeak-specific learning operation and should live in the server instead of the app.

Verified later against local backend source:

- no current `dailyspeak/polish` endpoint was found
- this remains planned backend work, not an existing contract

### Text to Speech

Use `manage-man-server` plus ElevenLabs and return playable audio to iOS.

Client playback should move to `AVPlayer`-style remote/local file playback rather than `AVSpeechSynthesizer`.

### Recording Upload

The app should record audio locally as `m4a`, upload it through `manage-man-server`, and persist the file in Cloudflare R2.

Storage rule:

- object storage keeps the file
- app stores local temporary files only
- server/database stores metadata only

### Speech Recognition Scope

For this release pass, local `SFSpeechRecognizer` remains acceptable for live transcript capture.

This keeps scope under control while still delivering a complete shipping chain:

- auth works
- translation works
- polish works
- TTS works
- audio upload works

Server-side transcription/scoring can come in a later pass.

## Release Modules To Add Now

### Onboarding

Short, product-specific onboarding that explains:

- what DailySpeak is
- how to use the staged speaking path
- what AI helps with
- that voice and notification permissions are requested only when needed

### Auth Screens

Provide:

- continue with Apple
- continue with email
- continue as guest

### Settings

Settings should expose:

- account status
- sign in / sign out
- notification settings
- feedback
- rate app
- privacy policy
- terms of service
- about/version
- clear local learning data

### Notifications

Add local daily reminders first:

- enable/disable
- reminder time picker
- permission request only when toggled on

Remote push is not required for this pass, but the app shell should not block adding it later.

### Feedback

Add email feedback with diagnostics:

- app version
- iOS version
- auth mode
- backend user id if available

### Review Prompt

Prompt after real value moments:

- finishing a task
- finishing a stage
- sustained usage over time

### Legal / Compliance

Add visible, stable links for:

- Privacy Policy
- Terms of Service

Also ensure microphone / speech permission purpose strings are present and clear.

## Data Strategy

This pass should intentionally keep local learning data as the source of truth for study progress.

That means:

- task completion stays local
- stage progress stays local
- writing drafts stay local
- onboarding/settings toggles stay local

The server is introduced for:

- identity
- AI features
- file handling
- future expansion

This avoids coupling app usability to server sync before the product shell is stable.

## Implementation Principles

- Reuse the ReSelf architectural pattern where it reduces product risk.
- Keep DailySpeak lesson rendering independent from backend availability.
- Move secrets and third-party AI access out of the app.
- Add release shell modules before visual flourishes.
- Treat guest mode as a first-class path, but not a complete cloud path.

## Success Criteria

DailySpeak should be considered successfully upgraded when:

- first launch shows onboarding and auth choice
- Apple/email/guest flows all work
- backend token is persisted and attached to protected server APIs
- translation no longer uses direct OpenAI from iOS
- TTS no longer depends on local synthesizer as the main path
- user audio can be recorded and uploaded through server to R2
- settings, feedback, review, notifications, and legal links are visible and usable
- the existing course flow still works from local bundled data
