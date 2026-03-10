#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/levi/project/IOS/DailySpeak/DailySpeak"
RESOURCES="$ROOT/Resources"
OVERVIEW="$ROOT/Views/TaskOverviewView.swift"
FLOW="$ROOT/Views/LearningFlowView.swift"
REVIEW="$ROOT/Views/ReviewStepView.swift"
COURSE_DATA="$ROOT/Models/CourseData.swift"
LESSON_MODEL="$ROOT/Models/LessonRepository.swift"

expected_stage_count() {
  case "$1" in
    1|2) echo 8 ;;
    3|4) echo 5 ;;
    5) echo 6 ;;
    6) echo 5 ;;
    7) echo 4 ;;
    8) echo 5 ;;
    9) echo 6 ;;
    *) return 1 ;;
  esac
}

for stage in 1 2 3 4 5 6 7 8 9; do
  manifest="$RESOURCES/stage${stage}_manifest.json"
  lesson_count="$(expected_stage_count "$stage")"
  echo "Checking Stage ${stage} manifest..."
  [ -f "$manifest" ]
  jq -e \
    --argjson stage "$stage" \
    --arg stage_label "Stage $stage" \
    --argjson lesson_count "$lesson_count" '
      .stage_id == $stage
      and .stage_label == $stage_label
      and (.lessons | length == $lesson_count)
    ' "$manifest" >/dev/null

  while IFS= read -r filename; do
    lesson="$RESOURCES/$filename"
    [ -f "$lesson" ]
    jq -e \
      --argjson stage "$stage" '
      has("id")
      and has("topic")
      and has("strategy")
      and has("vocabulary")
      and has("phrases")
      and has("framework")
      and has("samples")
      and has("practice")
      and (.topic.stage == $stage)
      and (.strategy.angles | length == 4)
      and (.strategy.sequence | length == 3)
      and (.strategy.content_ratio | length == 3)
      and (.samples | length == 3)
    ' "$lesson" >/dev/null
  done < <(jq -r '.lessons[].filename' "$manifest")
done

echo "Checking structured lesson repository wiring..."
rg -q 'struct LessonManifest' "$LESSON_MODEL"
rg -q 'struct LessonContent' "$LESSON_MODEL"
rg -q 'protocol LessonContentSource' "$LESSON_MODEL"
rg -q 'struct BundleLessonContentSource' "$LESSON_MODEL"
rg -q 'enum LessonRepository' "$LESSON_MODEL"
rg -q 'loadTasks\(forStage' "$LESSON_MODEL"
! rg -q 'loadStageOneTasks' "$LESSON_MODEL"
rg -q 'LessonRepository\.loadTasks\(forStage: 1\)' "$COURSE_DATA"
rg -q 'LessonRepository\.loadTasks\(forStage: 9\)' "$COURSE_DATA"

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
! rg -q 'label: "Stage 1 Lesson"' "$FLOW"
! rg -q 'label: "Stage 1 Lesson"' "$REVIEW"

echo "PASS: Multi-stage lesson data assertions passed"
