# DailySpeak Task Overview Reveal Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the current overview stagger animation with a repeatable, cinematic task reveal flow that reuses the existing hero card content, docks it back to the page header, and then progressively reveals learning focus and step states.

**Architecture:** `TaskOverviewView` will move from loosely coordinated booleans to a single presentation phase model plus per-element reveal state. The hero card content will be rendered by one shared view in both centered and docked modes so the page feels like one card moving through space rather than two unrelated cards.

**Tech Stack:** SwiftUI, local view state, async animation sequencing with `Task.sleep`, xcodebuild, lightweight Python check scripts

---

### Task 1: Add Guardrails For The New Reveal Flow

**Files:**
- Create: `tests/check_task_overview_reveal_structure.py`
- Modify: `DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Write a Python check that expects:
- an `OverviewPresentationPhase` enum
- a dedicated hero overlay/docked rendering split
- a per-step display state model

**Step 2: Run test to verify it fails**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: FAIL because the current file does not contain the new state machine.

**Step 3: Write minimal implementation**

Add the new phase enum and per-step display-state definitions in `TaskOverviewView.swift`.

**Step 4: Run test to verify it passes**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

### Task 2: Introduce Hero Card Reveal State

**Files:**
- Modify: `DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Extend the same check script so it expects:
- hero title reveal progress state
- hero description reveal progress state
- a reveal runner method such as `runRevealSequence`

**Step 2: Run test to verify it fails**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: FAIL

**Step 3: Write minimal implementation**

Add the hero reveal state and the sequence runner skeleton without changing the page layout yet.

**Step 4: Run test to verify it passes**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

### Task 3: Split The Hero Into Centered And Docked Presentation

**Files:**
- Modify: `DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Extend the check script to require a reusable hero card content view plus two render paths:
- centered reveal hero
- docked header hero

**Step 2: Run test to verify it fails**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: FAIL

**Step 3: Write minimal implementation**

Refactor the existing top card to use shared content. Render it in the center during the early phases with dark overlay and near-field transform, then render the docked version once the hero reaches the top.

**Step 4: Run test to verify it passes**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

### Task 4: Rebuild Overview Section Timing

**Files:**
- Modify: `DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Extend the check script to require:
- separate visibility gates for `学习重点`
- separate visibility gates for `学习流程`
- CTA visibility tied to the final `ready` phase

**Step 2: Run test to verify it fails**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: FAIL

**Step 3: Write minimal implementation**

Replace the current broad `appear`/`allAnimationsComplete` behavior with section-specific reveal flags that are advanced by the reveal sequence.

**Step 4: Run test to verify it passes**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

### Task 5: Replace Step Spinner Logic With Settling States

**Files:**
- Modify: `DailySpeak/Views/TaskOverviewView.swift`

**Step 1: Write the failing test**

Extend the check script to require:
- step display states `hidden`, `spinning`, `unlocked`, `locked`
- a progression method that settles step 1 unlocked and later steps locked

**Step 2: Run test to verify it fails**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: FAIL

**Step 3: Write minimal implementation**

Replace the old shared `currentLoadingStep` presentation logic with per-step reveal state so step rows can visually settle into unlocked/locked end states after spinning.

**Step 4: Run test to verify it passes**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

### Task 6: Build And Validate

**Files:**
- Test: `tests/check_task_overview_reveal_structure.py`
- Test: `DailySpeak.xcodeproj`

**Step 1: Run structural check**

Run: `python3 tests/check_task_overview_reveal_structure.py`
Expected: PASS

**Step 2: Run project build**

Run: `xcodebuild -project DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build`
Expected: `** BUILD SUCCEEDED **`

**Step 3: Review warnings**

Inspect build output and confirm no new warnings were introduced by the overview refactor.

**Step 4: Commit**

```bash
git add docs/plans/2026-03-13-dailyspeak-task-overview-reveal-design.md docs/plans/2026-03-13-dailyspeak-task-overview-reveal.md tests/check_task_overview_reveal_structure.py DailySpeak/Views/TaskOverviewView.swift
git commit -m "feat: add cinematic task overview reveal"
```
