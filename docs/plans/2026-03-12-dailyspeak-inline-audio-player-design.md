# DailySpeak Inline Audio Player Design

**Goal:** Replace the global mini player experiment with an inline playback experience that keeps controls in context: tapping play should turn the local control into an active waveform player with progress, pause, and scrubbing.

**Why This Is Better**

The mini player solved discoverability but introduced layout conflicts and pulled attention away from the learning content. DailySpeak works better when playback feels attached to the sentence, answer, or translation being heard.

The correct interaction model is:

- tap play
- the local control transforms into a playing state
- waveform motion signals playback
- a progress bar shows position
- the user can pause or scrub without leaving context

This keeps the interaction clear without adding a second layer of app chrome.

**Scope**

- Remove the global bottom mini player.
- Restore the home screen structure.
- Upgrade English playback controls to inline player controls.

**Service Design**

`EnglishSpeechPlayer` remains the shared playback owner, but it must evolve from a simple `play/stop` service into a real playback state store.

It should publish:

- current playback id
- loading id
- paused id
- current time
- total duration
- progress ratio

It should support:

- start / switch playback
- pause
- resume
- seek
- stop

Use `AVPlayer` periodic time observation to drive the progress UI.

**UI Design**

There are two inline control styles:

1. `compact`
   For vocabulary and phrase rows. Default state is a small icon button. Active state expands into a narrow capsule with waveform bars, pause/resume, and slider.

2. `prominent`
   For larger surfaces like translation playback and sample answers. Default state is a call-to-action button. Active state becomes a wider player row with waveform, pause/resume, current time, total duration, and a draggable slider.

**Behavior**

- Loading: show spinner in place of waveform.
- Playing: show animated waveform and pause button.
- Paused: show still waveform plus resume button and keep current progress.
- Ended: collapse back to default button.
- Leaving the page: stop playback so there is no orphan audio state without controls.

**Home Screen**

Restore `StageListView` to the pre-experiment structure. The home screen should not keep the added `Today` card or the extra focal animation layer from the previous experiment.

**Verification**

Because the project has no XCTest target, verification should use:

1. A shell guardrail that confirms:
   - `GlobalAudioMiniPlayer` is gone
   - `TodayFocusCard` is gone
   - inline player state and controls exist
2. `xcodebuild` simulator build verification.
