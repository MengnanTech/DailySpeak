#!/bin/bash

set -euo pipefail

ROOT="/Users/levi/project/IOS/DailySpeak"
CONTENT_FILE="$ROOT/DailySpeak/ContentView.swift"
STAGE_FILE="$ROOT/DailySpeak/Views/StageListView.swift"
PLAYER_FILE="$ROOT/DailySpeak/Services/EnglishSpeechPlayer.swift"
PRACTICE_FILE="$ROOT/DailySpeak/Views/PracticeView.swift"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

grep -q "GlobalAudioMiniPlayer" "$CONTENT_FILE" && fail "GlobalAudioMiniPlayer should be removed"
grep -q "TodayFocusCard" "$STAGE_FILE" && fail "TodayFocusCard should be removed"
grep -q "pausePlayback" "$PLAYER_FILE" || fail "pausePlayback missing from EnglishSpeechPlayer"
grep -q "seekPlayback" "$PLAYER_FILE" || fail "seekPlayback missing from EnglishSpeechPlayer"
grep -q "InlineAudioPlayerControl" "$PRACTICE_FILE" || fail "InlineAudioPlayerControl missing from PracticeView"

echo "PASS: inline audio player guardrails satisfied"
