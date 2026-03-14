#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SETTINGS_COMPONENTS="$ROOT/DailySpeak/Views/Components/SettingsComponents.swift"
APP_SETTINGS="$ROOT/DailySpeak/Views/Screens/AppSettingsView.swift"
PAYWALL="$ROOT/DailySpeak/Views/Screens/PaywallPlaceholderView.swift"
PERSONAL="$ROOT/DailySpeak/Views/Screens/PersonalCenterView.swift"
ONBOARDING="$ROOT/DailySpeak/Views/Shell/OnboardingView.swift"
SPLASH="$ROOT/DailySpeak/Views/Shell/SplashAnimationView.swift"
STAGE_LIST="$ROOT/DailySpeak/Views/StageListView.swift"
COURSE_DATA="$ROOT/DailySpeak/Models/CourseData.swift"
FLOW="$ROOT/DailySpeak/Views/LearningFlowView.swift"

echo "Checking settings component polish..."
rg -q 'struct SettingIconBadge: View' "$SETTINGS_COMPONENTS"
rg -q 'RoundedRectangle\\(cornerRadius: 24, style: \\.continuous\\)' "$SETTINGS_COMPONENTS"

echo "Checking settings screen sections..."
rg -q 'private var accountSection: some View' "$APP_SETTINGS"
rg -q 'sectionHeader\\(title: "Preferences"' "$APP_SETTINGS"

echo "Checking premium shell..."
rg -q 'private let benefits:' "$PAYWALL"
rg -q 'private var premiumHeader: some View' "$PAYWALL"

echo "Checking personal center shell..."
rg -q 'private var profileHeader: some View' "$PERSONAL"
rg -q 'private func miniStat\\(value: String, label: String, color: Color\\) -> some View' "$PERSONAL"

echo "Checking onboarding motion..."
rg -q '@State private var pageAppeared: Set<Int> = \\[\\]' "$ONBOARDING"
rg -q 'let accentEnd: Color' "$ONBOARDING"

echo "Checking splash sequence..."
rg -q '@State private var logoScale: CGFloat = 0.3' "$SPLASH"
rg -q '@State private var ring3Expand = false' "$SPLASH"

echo "Checking stage list header polish..."
rg -q 'Text\\("\\\\\\(totalCompleted\\) done"\\)' "$STAGE_LIST"
rg -q 'Text\\("Stage \\\\\\(currentStage.id\\)"\\)' "$STAGE_LIST"

echo "Checking vocabulary icon cleanup..."
rg -q 'case \\.vocabulary:  "textbook"' "$COURSE_DATA"
if rg -q 'Image\\(systemName: category\\.icon\\)' "$FLOW"; then
  echo "Vocabulary category icon should have been removed from LearningFlowView" >&2
  exit 1
fi
