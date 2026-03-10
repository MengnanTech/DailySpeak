# Stage 2-9 JSON Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand DailySpeak from a Stage 1-only structured lesson bundle into a full Stage 1-9 JSON-driven course with 52 formal lessons.

**Architecture:** Keep the existing Stage 1 lesson schema as the single content contract, add one manifest per stage, and generalize the repository so `CourseData` reads every stage from bundled JSON. Use the user-approved Stage 2-9 curriculum list as the source of truth for stage names, lesson titles, and lesson counts. Keep UI changes narrow: remove Stage 1-only wording and rely on the loaded lesson stage metadata.

**Tech Stack:** SwiftUI, Foundation `Codable`, bundled JSON resources, shell validation scripts.

---

### Task 1: Add failing multi-stage validation

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1:** Extend the validation script so it asserts:
- `stage1_manifest.json` to `stage9_manifest.json` all exist
- lesson counts are `8, 8, 5, 5, 6, 5, 4, 5, 6`
- every referenced lesson JSON exists and contains the required Stage 1 schema

**Step 2:** Run the script and confirm it fails because Stage 2-9 resources do not exist yet.

### Task 2: Generalize lesson loading

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/LessonRepository.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/CourseData.swift`

**Step 1:** Replace the Stage 1-only repository entry point with a reusable `loadTasks(forStage:)`.

**Step 2:** Add stage metadata in `CourseData` that matches the approved curriculum.

**Step 3:** Update all nine `Stage(...)` entries to load from JSON manifests instead of placeholders.

### Task 3: Generate Stage 2-9 manifests and lesson resources

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage2_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage3_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage4_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage5_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage6_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage7_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage8_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/stage9_manifest.json`
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/s02_q09_*.json` through `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/s09_q52_*.json`

**Step 1:** Generate per-stage manifests using the approved stage/task structure.

**Step 2:** Generate one full structured lesson JSON per task using the existing schema:
- `topic`
- `strategy`
- `vocabulary`
- `phrases`
- `framework`
- `samples`
- `practice`

**Step 3:** Keep lesson ids globally unique as `1...52` to avoid stage lookup collisions in existing navigation state.

### Task 4: Remove Stage 1-only lesson wording from JSON-backed views

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/ReviewStepView.swift`

**Step 1:** Replace hard-coded `Stage 1 Lesson` chips with the actual `lessonContent.topic.stageLabel` when present.

**Step 2:** Leave the fallback wording intact for placeholder tasks if any remain.

### Task 5: Run validation and build verification

**Files:**
- No code changes expected

**Step 1:** Run `bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh` and verify it passes.

**Step 2:** Run an `xcodebuild` check for the DailySpeak app target.

**Step 3:** Search for stale Stage 1-only repository wiring and preview-era wording that should no longer control course loading.
