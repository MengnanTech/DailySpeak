# DailySpeak Task Overview Reveal Design

**Context**

`TaskOverviewView` currently behaves like a static scroll page with a few staggered sub-animations. The new requirement is a repeatable, game-like "task reveal" sequence that plays every time a user opens a task overview.

**Goal**

Turn task overview entry into a cinematic reveal sequence:

1. Reuse the current top hero card content as a centered near-field card.
2. Present that card on a darkened background with a subtle 3D entrance.
3. Reveal the title first, then progressively reveal the description.
4. Dock the same card back to the real top position in the page.
5. Reveal `学习重点`, then `学习流程`.
6. Present step rows with a staged "spinning -> settled" effect:
   - Step 1 settles as unlocked.
   - Remaining steps settle as locked.
7. Show the bottom CTA only after the reveal sequence completes.

**Non-goals**

- Do not create a separate reward card with different content.
- Do not skip the animation on repeat entry.
- Do not replace the overview data model.
- Do not redesign the task detail content itself.

**Experience Model**

The animation should feel like a quest card or item unlock:

- The card appears in front of the user, not already embedded in the scroll.
- The page background temporarily darkens to focus attention.
- The card content reveals in layers, not all at once.
- Once the hero completes, the page structure assembles beneath it.

**Interaction Rules**

- The full reveal runs every time the task overview opens.
- The user should not need to scroll to see the reveal sequence.
- The CTA should remain hidden until the reveal is finished.
- Locked steps should not visually appear as locked until they have completed their own presentation cycle.

**Architecture**

Introduce an explicit presentation phase state machine in `TaskOverviewView` instead of independently scheduled booleans. The page will render through a shared hero card view that can appear in two modes:

- `centeredReveal`: dark, near-field, cinematic
- `dockedHeader`: normal top-of-page layout

The overview body will be assembled progressively with separate flags for:

- hero title progress
- hero description progress
- focus section visibility
- flow section visibility
- per-step presentation state

**Planned Phase Sequence**

1. `heroEntrance`
2. `heroTitleReveal`
3. `heroDescriptionReveal`
4. `heroDockToTop`
5. `focusReveal`
6. `flowReveal`
7. `stepProgression`
8. `ready`

**Step Presentation Model**

Each overview step should use a dedicated display state rather than inferring from one spinner variable:

- `hidden`
- `spinning`
- `unlocked`
- `locked`

Step 1 transitions `hidden -> spinning -> unlocked`.
Later steps transition `hidden -> spinning -> locked`.

**Animation Direction**

- Hero entrance: slight `scale`, upward depth, soft perspective, eased drop-in.
- Title reveal: fade + upward easing.
- Description reveal: typewriter or progressive character mask.
- Dock motion: hero card shrinks and moves into the normal header position.
- Section reveal: cards rise in from below with opacity.
- Step reveal: row appears, badge spins, then settles into unlocked/locked form.

**Timing Guidance**

The total sequence should feel premium but not slow. Target duration is about 2.2s to 2.8s, not 4s.

**Files Expected To Change**

- `DailySpeak/Views/TaskOverviewView.swift`
- `docs/plans/2026-03-13-dailyspeak-task-overview-reveal.md`
- small targeted test/check scripts under `tests/`

**Verification**

- Build with `xcodebuild -project DailySpeak.xcodeproj -scheme DailySpeak -configuration Debug -destination 'generic/platform=iOS Simulator' build`
- Keep current behavior intact outside the overview entrance flow
- Confirm no new compiler warnings are introduced
