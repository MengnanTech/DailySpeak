# Q01 JSON Preview Design

**Context**

DailySpeak currently renders course content from in-memory placeholder data in [`CourseData.swift`](/Users/levi/project/IOS/DailySpeak/DailySpeak/Models/CourseData.swift). The user wants to preview what a real JSON-driven lesson would look like inside the existing app flow, using `q01_describe_a_person.json` as the first concrete lesson.

**Goal**

Render `q01_describe_a_person.json` inside the existing `Stage 1 -> Task 1 -> TaskOverviewView -> LearningFlowView` flow, while allowing the page layout to reflect the richer JSON structure instead of the current placeholder-only fields.

**Scope**

- Only `q01_describe_a_person.json`
- Only Stage 1 / Task 1
- Use the existing navigation flow
- Upgrade overview and learning step layouts where needed to show richer content

**Out of Scope**

- General JSON course engine
- Multi-lesson JSON loading
- Back-office authoring or content management
- Migrating all other tasks away from placeholders

**Design**

1. Add the JSON file to the app bundle under a new local resources folder.
2. Add a dedicated preview decoder/adapter that reads `q01_describe_a_person.json` and maps it into:
   - the existing `SpeakingTask` fields needed by the app
   - a new optional preview payload with richer JSON-only sections
3. Replace Stage 1 / Task 1 with the adapted preview lesson. If loading fails, fall back to the current placeholder to keep the app usable.
4. Upgrade `TaskOverviewView` for preview-backed tasks:
   - richer hero with topic, prompt, target, and content counts
   - summary cards for vocabulary / phrases / samples / framework
   - learning module preview based on actual step content
5. Upgrade `LearningFlowView` step bodies for preview-backed tasks:
   - `Strategy`: native usage statement, dimensions, sequence, principles, misfires
   - `Vocabulary`: extracted vs expanded vocabulary with notes
   - `Phrases`: meanings, band/source, and notes
   - `Framework`: band 6/7/8 framework groups and upgrade path
   - `Samples`: style, word count, answer, native features
   - `Practice`: prompt + checklist from the JSON template

**Why This Design**

- It gives a real in-app preview instead of a separate mock page.
- It keeps risk low by changing only one task.
- It moves the app toward JSON-driven content without forcing a full architecture rewrite before seeing the result.

**Validation**

- Build the app with `xcodebuild`
- Launch in simulator
- Navigate to Stage 1 / Task 1
- Verify the overview and all step pages show JSON-backed content instead of placeholder-only content
