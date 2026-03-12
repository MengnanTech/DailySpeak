# DailySpeak Splash Animation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade the DailySpeak splash into a longer, multi-stage brand animation with a smoother fade-out to the app.

**Architecture:** Keep the splash mounted from `DailySpeakApp`, but refactor `SplashAnimationView` into a staged animation sequence with background drift, logo settle-in, sequential copy reveal, and a short resolved hold before exit. Use a small shell guardrail script for structural verification and finish with a simulator build.

**Tech Stack:** SwiftUI, shell guardrail tests, Xcode build tooling

---

### Task 1: Add a failing splash-animation guardrail

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/test_splash_animation.sh`

**Step 1: Write the failing test**

Create a shell script that fails unless:

- `SplashAnimationView.swift` contains staged state such as `backgroundDrift`
- `SplashAnimationView.swift` contains a logo entrance state such as `logoSettled`
- `SplashAnimationView.swift` contains a copy reveal state such as `showWordmark`
- `SplashAnimationView.swift` contains a longer splash delay marker such as `2_300_000_000`
- `DailySpeakApp.swift` still references `SplashAnimationView`

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_splash_animation.sh`

Expected: FAIL because the current splash only has the simple pulse/lift animation.

### Task 2: Implement the richer splash sequence

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/Shell/SplashAnimationView.swift`

**Step 1: Use the failing guardrail as red**

Keep the shell test red before editing the splash view.

**Step 2: Write minimal implementation**

- Replace the looped two-state animation with staged state variables.
- Add layered background glow drift.
- Add logo card rotation-and-settle motion plus subtle supporting accents.
- Reveal title and subtitle in sequence.
- Increase total presentation time and add a short resolved hold.

**Step 3: Run the splash test**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_splash_animation.sh`

Expected: PASS.

### Task 3: Smooth the splash exit from app root

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/DailySpeakApp.swift`

**Step 1: Keep splash handoff explicit**

Use the splash callback to hide the cover with animation instead of an abrupt state flip.

**Step 2: Run the splash test again**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_splash_animation.sh`

Expected: PASS.

### Task 4: Verify the full app still builds

**Files:**
- Existing test: `/Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`

**Step 1: Run regression guardrail**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_inline_audio_player.sh`

Expected: PASS.

**Step 2: Build for simulator**

Run: `xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`

Expected: BUILD SUCCEEDED.
