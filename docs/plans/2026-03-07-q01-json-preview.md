# Q01 JSON Preview Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Render `q01_describe_a_person.json` inside the existing DailySpeak lesson flow so the app shows a realistic JSON-driven lesson preview.

**Architecture:** Bundle the JSON file with the app, decode it into a dedicated preview model, adapt that model into `SpeakingTask`, and let `TaskOverviewView` / `LearningFlowView` switch to richer layouts when preview data exists. Keep every other lesson on the existing placeholder path.

**Tech Stack:** SwiftUI, Foundation `Codable`, bundled JSON resources, existing DailySpeak navigation/views.

---

### Task 1: Add bundled JSON preview source

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/q01_describe_a_person.json`

**Step 1:** Copy the existing source JSON into the app's `Resources` folder.

**Step 2:** Verify the file exists in the synced Xcode group path.

### Task 2: Add preview decoder and adapter

**Files:**
- Create: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/JSONLessonPreview.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/CourseData.swift`

**Step 1:** Define decodable structs for the `q01` JSON shape.

**Step 2:** Define a richer preview payload used only by the UI when JSON data exists.

**Step 3:** Add an adapter that maps the decoded preview into `SpeakingTask`.

**Step 4:** Replace Stage 1 / Task 1 with the adapted preview task, with placeholder fallback on decode failure.

### Task 3: Upgrade task overview for preview-backed lessons

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/TaskOverviewView.swift`

**Step 1:** Add a preview-aware overview branch.

**Step 2:** Render richer summary modules, prompt, target, counts, and lesson focus.

**Step 3:** Keep the existing overview path intact for non-preview tasks.

### Task 4: Upgrade learning flow steps for preview-backed lessons

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`

**Step 1:** Add preview-aware content to `StrategyStepView`.

**Step 2:** Extend vocabulary and phrase presentation for JSON metadata.

**Step 3:** Add richer framework and sample rendering for preview tasks.

**Step 4:** Add JSON checklist support to the practice step.

### Task 5: Verify build and runtime entry path

**Files:**
- Modify if needed: `/Users/levi/project/IOS/DailySpeak/DailySpeak/DailySpeakApp.swift`

**Step 1:** Build the app with `xcodebuild`.

**Step 2:** If the build passes, run the app in simulator and inspect Stage 1 / Task 1.

**Step 3:** Capture screenshots of the overview and core learning steps.
