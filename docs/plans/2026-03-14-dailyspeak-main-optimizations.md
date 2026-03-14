# DailySpeak Main Optimizations Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Merge the UI and interaction optimizations from `/Users/levi/Downloads/DailySpeak-main` into the active DailySpeak workspace without regressing newer flow work already present here.

**Architecture:** Treat the downloaded directory as a style/interaction reference rather than a full source of truth. Copy over the shell-level improvements where that version is ahead, preserve the newer overview/lesson flow already in this repo, and add a lightweight regression script that locks the imported optimizations in place.

**Tech Stack:** SwiftUI, shell-based structural checks, existing DailySpeak theme helpers.

---

### Task 1: Add a failing regression check for the imported optimizations

**Files:**
- Create: `tests/check_main_ported_optimizations.sh`

**Step 1: Write the failing test**

Add a shell script that asserts the optimized structures are present in the target SwiftUI files.

**Step 2: Run test to verify it fails**

Run: `bash tests/check_main_ported_optimizations.sh`

Expected: `rg` failures because the current repo does not yet include the imported shell/UI updates.

**Step 3: Write minimal implementation**

Port the downloaded version's shell/UI changes into the local files, while keeping newer current-workspace behavior where it is already ahead.

**Step 4: Run test to verify it passes**

Run: `bash tests/check_main_ported_optimizations.sh`

Expected: exit 0.

### Task 2: Merge UI shell improvements from the downloaded version

**Files:**
- Modify: `DailySpeak/Views/Components/SettingsComponents.swift`
- Modify: `DailySpeak/Views/Screens/AppSettingsView.swift`
- Modify: `DailySpeak/Views/Screens/PaywallPlaceholderView.swift`
- Modify: `DailySpeak/Views/Screens/PersonalCenterView.swift`
- Modify: `DailySpeak/Views/Shell/OnboardingView.swift`
- Modify: `DailySpeak/Views/Shell/SplashAnimationView.swift`
- Modify: `DailySpeak/Views/StageListView.swift`
- Modify: `DailySpeak/Models/CourseData.swift`
- Modify: `DailySpeak/Views/LearningFlowView.swift`

**Step 1: Import the settings/profile shell updates**

Bring over the redesigned cards, icon badges, settings sections, premium shell, and personal center layout.

**Step 2: Import onboarding and splash motion updates**

Bring over the animated onboarding page metadata and splash sequencing.

**Step 3: Import stage-list header polish**

Bring over the compact stats treatment in the stage header while leaving task/overview behavior intact.

**Step 4: Import the vocabulary icon cleanup**

Update the vocabulary step symbol and remove the redundant category icons from the vocabulary switcher.

### Task 3: Verify no regressions against existing structural checks

**Files:**
- Verify: `test_q01_preview_layout.sh`
- Verify: `test_splash_animation.sh`
- Verify: `tests/check_stage_carousel_size.py`
- Verify: `tests/check_vocabulary_step_icon.py`

**Step 1: Run the new optimization check**

Run: `bash tests/check_main_ported_optimizations.sh`

**Step 2: Run existing focused checks**

Run:
- `bash test_q01_preview_layout.sh`
- `bash test_splash_animation.sh`
- `python3 tests/check_stage_carousel_size.py`
- `python3 tests/check_vocabulary_step_icon.py`

**Step 3: Report actual verification status**

State which commands passed and note any remaining gaps instead of assuming completion.
