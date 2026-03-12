# DailySpeak Splash Animation Design

**Date:** 2026-03-13

## Goal

Keep the splash screen, but make it feel complete instead of abrupt by extending the timeline, layering the motion, and softening the exit into the main app.

## Current Problem

- The current splash completes in about 1.25 seconds.
- Pulse and lift begin immediately, so the motion reads as one generic loop instead of a deliberate sequence.
- The screen exits as soon as the timer ends, which makes the transition feel cut off.
- The scene lacks depth around the logo, so the brand moment feels unfinished.

## Product Direction

The splash should feel like a short premium intro, not a placeholder:

- A soft background atmosphere starts first.
- The logo enters with a more intentional settle-in motion.
- Brand copy appears in sequence instead of all at once.
- The screen holds briefly after the animation resolves.
- The final fade should feel like a handoff to the app, not a forced dismissal.

## Recommended Animation Structure

### Stage 1: Atmosphere

- Background gradient remains warm and calm.
- Add at least two drifting glow layers with slightly different timing.
- Add a few subtle accent particles or orbit strokes around the logo area.

### Stage 2: Logo Entrance

- The rounded-square logo card should begin slightly larger and rotated.
- It rotates into place and settles with a gentle upward motion.
- The mic icon can scale in slightly after the card starts moving.

### Stage 3: Copy Reveal

- App name fades and rises in first.
- Tagline fades in after a short delay.
- Copy should become readable before the splash exits.

### Stage 4: Resolve and Exit

- Hold the completed composition for a short beat.
- Fade the splash out rather than cutting away.
- Total runtime should land around 2.2 to 2.6 seconds.

## Visual Constraints

- Keep the existing brand palette.
- Avoid noisy particle systems or exaggerated bounce.
- Use only a few polished elements: glow, orbit, scale, rotation, fade, and slight drift.
- The motion should remain smooth on simulator and device.

## Technical Approach

- Keep `SplashAnimationView` as the dedicated splash container.
- Replace the current two-state loop (`pulse`, `lift`) with staged state variables that map to the new sequence.
- Keep `DailySpeakApp` in control of when the splash disappears, but route completion through a softer fade window.
- Use explicit animation timings and one coordinated task instead of a perpetual loop as the main presentation.

## Verification

- Add a shell guardrail script for splash-specific markers so the structure can be checked quickly.
- Verify the new staged state names and longer completion timing exist in the splash view.
- Build the iOS app for the simulator after the change.
