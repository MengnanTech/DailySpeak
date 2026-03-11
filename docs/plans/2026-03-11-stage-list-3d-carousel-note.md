# StageList 3D Carousel Note

**Context**

DailySpeak's home page (`StageListView`) is currently functional, but visually flat. A reference video was reviewed to explore whether the home page could gain a stronger focal point without turning into a decorative concept UI.

**Definition**

The target effect is best described as a `pseudo-3D perspective card carousel`, not true 3D.

It combines:

- a centered hero card as the main focus
- partial side peeks of adjacent cards
- subtle `Y`-axis tilt on non-active cards
- scale, brightness, saturation, and shadow changes to create depth
- view-aligned snapping so the active card locks into the center
- short content transitions so stage info changes with motion instead of hard cuts

Related labels that are accurate in design or engineering discussion:

- `perspective card carousel`
- `3D-tilted card carousel`
- `cover-flow style stage carousel`
- `stacked hero cards with perspective`

**Why It Fits DailySpeak**

This effect should not be treated as a postcard editor or visual toy. The goal is to improve stage selection clarity on the home page.

For DailySpeak, the effect should mean:

- one stage becomes the clear current focus
- neighboring stages remain visible as context
- the user can swipe to compare stages quickly
- the home page feels more intentional without hiding course progress or next actions

**Translation Into Product Language**

Recommended Chinese wording for internal discussion:

- `带透视倾斜的主视觉卡片轮播`
- `具有空间层次感的伪 3D stage 切换`
- `类似 Cover Flow 的阶段卡片滑动效果`

**Implementation Notes**

If adopted, the effect should remain constrained to the stage hero layer:

- keep existing course and progress data models
- do not introduce theme pickers or decorative editors from the reference video
- pair the hero carousel with a practical next-step action
- validate readability, swipe clarity, and CTA hit area before merge

**Candidate Branch**

An implementation prototype currently exists on:

- `codex/stage-list-hero-carousel`
