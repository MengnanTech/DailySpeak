#!/bin/bash

set -euo pipefail

ROOT="/Users/levi/project/IOS/DailySpeak"
SPLASH_FILE="$ROOT/DailySpeak/Views/Shell/SplashAnimationView.swift"
APP_FILE="$ROOT/DailySpeak/DailySpeakApp.swift"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

grep -q "backgroundDrift" "$SPLASH_FILE" || fail "backgroundDrift state missing from SplashAnimationView"
grep -q "logoSettled" "$SPLASH_FILE" || fail "logoSettled state missing from SplashAnimationView"
grep -q "showWordmark" "$SPLASH_FILE" || fail "showWordmark state missing from SplashAnimationView"
grep -q "2_300_000_000" "$SPLASH_FILE" || fail "Splash animation duration should be extended to around 2.3 seconds"
grep -q "SplashAnimationView" "$APP_FILE" || fail "DailySpeakApp should still present SplashAnimationView"

echo "PASS: splash animation guardrails satisfied"
