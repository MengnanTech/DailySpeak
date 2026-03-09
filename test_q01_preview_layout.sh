#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/levi/project/IOS/DailySpeak/DailySpeak"
RESOURCES="$ROOT/Resources"
MANIFEST="$RESOURCES/stage1_manifest.json"
OVERVIEW="$ROOT/Views/TaskOverviewView.swift"
FLOW="$ROOT/Views/LearningFlowView.swift"
REVIEW="$ROOT/Views/ReviewStepView.swift"
COURSE_DATA="$ROOT/Models/CourseData.swift"
LESSON_MODEL="$ROOT/Models/LessonRepository.swift"

echo "Checking Stage 1 manifest..."
jq -e '
  .stage_id == 1
  and .stage_label == "Stage 1"
  and (.lessons | length == 8)
' "$MANIFEST" >/dev/null

while IFS= read -r filename; do
  lesson="$RESOURCES/$filename"
  [ -f "$lesson" ]
  jq -e '
    has("id")
    and has("topic")
    and has("strategy")
    and has("vocabulary")
    and has("phrases")
    and has("framework")
    and has("samples")
    and has("practice")
    and (.samples | length == 3)
  ' "$lesson" >/dev/null
done < <(jq -r '.lessons[].filename' "$MANIFEST")

echo "Checking Stage 1 repository wiring..."
rg -q 'struct LessonManifest' "$LESSON_MODEL"
rg -q 'struct LessonContent' "$LESSON_MODEL"
rg -q 'protocol LessonContentSource' "$LESSON_MODEL"
rg -q 'struct BundleLessonContentSource' "$LESSON_MODEL"
rg -q 'enum LessonRepository' "$LESSON_MODEL"
rg -q 'loadStageOneTasks' "$LESSON_MODEL"
rg -q 'LessonRepository\.loadStageOneTasks\(\)' "$COURSE_DATA"

echo "Checking no preview naming remains..."
! rg -q 'LessonPreviewContent' "$ROOT"
! rg -q 'previewContent' "$ROOT"
! rg -q 'Q01 Preview' "$ROOT"
! rg -q 'JSON Preview' "$ROOT"
! rg -q 'PreviewTaskFactory' "$ROOT"

echo "Checking formal lesson UI wording..."
rg -q 'lessonContent' "$OVERVIEW"
rg -q 'lessonContent' "$FLOW"
rg -q 'lessonContent' "$REVIEW"
rg -q 'struct ReviewStepView: View' "$REVIEW"
rg -q 'Rectangle\(\)' "$REVIEW"
! rg -q 'Text\("建议改法"\)' "$REVIEW"
rg -q 'Text\("Why it hurts"\)' "$REVIEW"
rg -q 'Text\("Try this"\)' "$REVIEW"
rg -q '"高分检查"' "$COURSE_DATA"
rg -q 'LearningStep\(id: 1, type: \.review\)' "$LESSON_MODEL"

echo "PASS: Stage 1 lesson data assertions passed"
