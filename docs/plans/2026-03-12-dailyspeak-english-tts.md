# DailySpeak English TTS Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace all English playback in DailySpeak with backend-generated MP3 playback while keeping translation on the verified backend contract.

**Architecture:** Add a single shared English speech player service on top of `DailySpeakAPIService`. It requests `/tts/english/mp3`, caches audio URLs by deterministic playback IDs, and plays them through `AVPlayer`. Existing playback buttons keep their places but call the shared service instead of local speech synthesis.

**Tech Stack:** SwiftUI, `AVFoundation`, `URLSession`, existing `APIClient`

---

### Task 1: Guardrail test first

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1: Write the failing test**

Add checks for:
- `DailySpeak/Services/EnglishSpeechPlayer.swift`
- `/tts/english/mp3` usage in `DailySpeakAPIService.swift`
- no `AVSpeechSynthesizer` in `LearningFlowView.swift` and `PracticeView.swift`

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`
Expected: FAIL before implementation because the new service file and endpoint wiring do not exist yet.

### Task 2: Add backend TTS API wiring

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/DailySpeakAPIService.swift`

**Step 1: Write minimal implementation**

Add DTOs and a method that calls:
- `POST /tts/english/mp3`
- body: `id`, `text`
- auth required
- returns a validated `audioUrl`

### Task 3: Add shared English playback service

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/EnglishSpeechPlayer.swift`

**Step 1: Write minimal implementation**

Build a shared `ObservableObject` service that:
- generates deterministic playback IDs
- caches audio URLs
- toggles playback for one active item at a time
- uses `AVPlayer` for remote MP3 playback

### Task 4: Migrate all English playback entry points

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/PracticeView.swift`

**Step 1: Replace local synthesizer use**

Change vocabulary, phrase, sample, and practice playback buttons to call the shared player.

### Task 5: Verify

**Files:**
- Test: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1: Run guardrail test**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`
Expected: PASS

**Step 2: Run build**

Run: `xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`
