# DailySpeak Inline Audio Player Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the global mini player and replace English playback buttons with inline controls that support waveform animation, progress, pause, and scrubbing.

**Architecture:** Extend `EnglishSpeechPlayer` into a richer playback state source, restore the home screen to its earlier layout, and replace key playback buttons with reusable inline controls embedded directly in their content context.

**Tech Stack:** SwiftUI, AVFoundation, xcodebuild, shell guardrail script

---

### Task 1: Add a failing guardrail

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`

**Step 1: Write the failing test**

The script should fail until:

- `GlobalAudioMiniPlayer` is absent
- `TodayFocusCard` is absent
- `pausePlayback` exists in `EnglishSpeechPlayer`
- `InlineAudioPlayerControl` exists in the views

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`
Expected: FAIL until the new inline player implementation is complete.

### Task 2: Upgrade playback service

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Services/EnglishSpeechPlayer.swift`

**Step 1: Write the failing test**

Use the guardrail script.

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`
Expected: FAIL because pause / progress state is missing.

**Step 3: Write minimal implementation**

- Add pause, resume, seek, current time, total duration, and progress tracking.
- Add periodic time observation for AVPlayer.

### Task 3: Remove mini player and restore home

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/ContentView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/StageListView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Use the guardrail script.

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`
Expected: FAIL because the mini player and home-card experiment still exist.

**Step 3: Write minimal implementation**

- Remove the mini player overlay.
- Restore the home screen layout.
- Remove the bottom CTA lifting that only existed for the mini player.

### Task 4: Add inline player controls

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/PracticeView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`

**Step 1: Write the failing test**

Use the guardrail script.

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`
Expected: FAIL because `InlineAudioPlayerControl` is not present.

**Step 3: Write minimal implementation**

- Add reusable inline player controls.
- Apply them to translation playback, sample answer playback, and the compact vocabulary / phrase style controls.
- Stop playback on page exit.

### Task 5: Verify build

**Step 1: Run checks**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`
Expected: PASS

Run: `xcodebuild -scheme DailySpeak -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -destination 'generic/platform=iOS Simulator' build`
Expected: BUILD SUCCEEDED
