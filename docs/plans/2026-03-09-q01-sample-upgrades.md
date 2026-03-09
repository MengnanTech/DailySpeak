# Q01 Sample Upgrades Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move `upgrade_expressions` from the shared framework block into each sample answer so upgrades are learned in the same context as the model answer.

**Architecture:** Keep `framework` limited to answer organization (`goal`, `default_structure`, `delivery_markers`) and make each `samples[]` entry self-contained with its own `band_guide` and `upgrades`. Update the JSON parsers and the preview UI to read upgrades from the currently selected sample instead of the shared framework block.

**Tech Stack:** SwiftUI, Codable/JSON decoding, jq/bash validation scripts, static HTML viewer

---

### Task 1: Tighten schema checks first

**Files:**
- Modify: `/Users/levi/project/oral-speaking-kb/test_viewer.sh`
- Modify: `/Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

**Step 1: Write the failing checks**
- Assert `framework.upgrade_expressions` is absent.
- Assert every `samples[]` item includes `upgrades`.

**Step 2: Run checks to verify failure**
Run:
```bash
bash /Users/levi/project/oral-speaking-kb/test_viewer.sh
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```
Expected: failure because current JSON still keeps upgrades under `framework`.

### Task 2: Move q01 data to the new schema

**Files:**
- Modify: `/Users/levi/project/oral-speaking-kb/q01_describe_a_person.json`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Resources/q01_describe_a_person.json`

**Step 1: Remove the old shared field**
- Delete `framework.upgrade_expressions`.

**Step 2: Add nested sample upgrades**
- Add `upgrades` arrays to each `samples[]` item.

### Task 3: Update parser and rendering

**Files:**
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/CourseData.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/JSONLessonPreview.swift`
- Modify: `/Users/levi/project/IOS/DailySpeak/DailySpeak/Views/LearningFlowView.swift`
- Modify: `/Users/levi/project/oral-speaking-kb/viewer.html`

**Step 1: Parse upgrades per sample**
- Add `upgrades` to `SampleAnswer` and raw sample JSON decoding.
- Remove framework-level upgrade parsing.

**Step 2: Render upgrades from selected sample**
- In the framework/sample preview, show the selected sample's upgrades.
- In the HTML viewer, render upgrades within each sample block.

### Task 4: Verify end-to-end

**Files:**
- Verify only

**Step 1: Re-run validation scripts**
Run:
```bash
bash /Users/levi/project/oral-speaking-kb/test_viewer.sh
bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh
```
Expected: pass.

**Step 2: Build the app**
Run:
```bash
xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```
Expected: `** BUILD SUCCEEDED **`
