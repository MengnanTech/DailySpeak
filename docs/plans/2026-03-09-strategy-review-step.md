# Strategy Review Step Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Split the current strategy preview into a pure answer-structure step and a separate high-score review step.

**Architecture:** Keep the JSON model unchanged and reorganize presentation at the step layer. Add a new `StepType` plus a dedicated SwiftUI view so the existing strategy data can be rendered in two different moments of the learning flow.

**Tech Stack:** SwiftUI, Foundation, shell-based layout verification

---

### Task 1: Add a failing structure check

**Files:**
- Modify: `test_q01_preview_layout.sh`

**Step 1: Write the failing test**

Add assertions that expect:
- a new review step type and title to exist
- the q01 preview task to include that step
- `StrategyStepView` to stop rendering high-score/pitfall/language sections directly

**Step 2: Run test to verify it fails**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

Expected: FAIL because the new step type and moved sections do not exist yet.

### Task 2: Introduce the review step in the learning flow

**Files:**
- Modify: `DailySpeak/Models/CourseData.swift`
- Modify: `DailySpeak/Models/JSONLessonPreview.swift`
- Modify: `DailySpeak/Views/LearningFlowView.swift`

**Step 1: Write minimal implementation**

Add:
- a new `StepType.review`
- localized title/subtitle/icon/color metadata
- q01 step ordering with review inserted after strategy
- a dedicated `ReviewStepView` in `LearningFlowView`

**Step 2: Move the content**

Keep `StrategyStepView` focused on:
- four thinking angles
- speaking sequence
- content split

Move into `ReviewStepView`:
- high-score reminders
- content pitfalls
- language fixes

**Step 3: Keep copy consistent**

Rename mixed labels to Chinese action-oriented copy so the two steps read as one flow instead of two unrelated cards.

### Task 3: Verify the change

**Files:**
- Verify: `test_q01_preview_layout.sh`
- Verify: `DailySpeak/Views/LearningFlowView.swift`

**Step 1: Run structure verification**

Run: `bash /Users/levi/project/IOS/DailySpeak/test_q01_preview_layout.sh`

Expected: PASS

**Step 2: Run build verification**

Run: `xcodebuild -project /Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj -scheme DailySpeak -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build`

Expected: BUILD SUCCEEDED
