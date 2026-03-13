#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/levi/project/IOS/DailySpeak/DailySpeak"
RESOURCES="$ROOT/Resources"
OVERVIEW="$ROOT/Views/TaskOverviewView.swift"
FLOW="$ROOT/Views/LearningFlowView.swift"
REVIEW="$ROOT/Views/ReviewStepView.swift"
COURSE_DATA="$ROOT/Models/CourseData.swift"
LESSON_MODEL="$ROOT/Models/LessonRepository.swift"
CONTENT_VIEW="$ROOT/ContentView.swift"
PRACTICE_AI="$ROOT/Models/PracticeAIService.swift"
API_SERVICE="$ROOT/Services/DailySpeakAPIService.swift"
INBOX_SERVICE="$ROOT/Services/InAppInboxService.swift"
PUSH_SERVICE="$ROOT/Services/PushNotificationService.swift"
WS_SERVICE="$ROOT/Services/WebSocketInboxClient.swift"
PERSONAL_CENTER="$ROOT/Views/Screens/PersonalCenterView.swift"
NOTIFICATIONS="$ROOT/Views/Screens/NotificationsView.swift"
AUTH_VIEW="$ROOT/Views/Screens/AuthLoginRegisterView.swift"
INITIAL_AUTH_VIEW="$ROOT/Views/Screens/InitialAuthChoiceView.swift"
APP_AUTH="$ROOT/App/AppState+Auth.swift"
ENGLISH_SPEECH="$ROOT/Services/EnglishSpeechPlayer.swift"
PBXPROJ="/Users/levi/project/IOS/DailySpeak/DailySpeak.xcodeproj/project.pbxproj"
DEBUG_ENTITLEMENTS="$ROOT/DailySpeak.entitlements"
RELEASE_ENTITLEMENTS="$ROOT/DailySpeak.Release.entitlements"

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

echo "Checking production shell files..."
[ -f "$ROOT/App/AppState.swift" ]
[ -f "$ROOT/App/AppState+Auth.swift" ]
[ -f "$ROOT/App/AppState+Inbox.swift" ]
[ -f "$ROOT/App/AppDelegate.swift" ]
[ -f "$ROOT/Services/APIClient.swift" ]
[ -f "$ROOT/Services/AuthService.swift" ]
[ -f "$ROOT/Services/DailySpeakAPIService.swift" ]
[ -f "$ROOT/Services/EnglishSpeechPlayer.swift" ]
[ -f "$ROOT/Services/NotificationService.swift" ]
[ -f "$ROOT/Services/PushNotificationService.swift" ]
[ -f "$ROOT/Views/Shell/SplashAnimationView.swift" ]
[ -f "$ROOT/Views/Shell/OnboardingView.swift" ]
[ -f "$ROOT/Views/Screens/InitialAuthChoiceView.swift" ]
[ -f "$ROOT/Views/Screens/AuthLoginRegisterView.swift" ]
[ -f "$ROOT/Views/Screens/NotificationsView.swift" ]
[ -f "$ROOT/Views/Screens/NotificationSettingsView.swift" ]
[ -f "$ROOT/Views/Screens/PersonalCenterView.swift" ]
[ -f "$ROOT/Views/Screens/AppSettingsView.swift" ]
[ -f "$ROOT/Views/Screens/PaywallPlaceholderView.swift" ]
[ -f "$DEBUG_ENTITLEMENTS" ]
[ -f "$RELEASE_ENTITLEMENTS" ]

echo "Checking Apple Sign In capability wiring..."
rg -q 'CODE_SIGN_ENTITLEMENTS = DailySpeak/DailySpeak.entitlements;' "$PBXPROJ"
rg -q 'CODE_SIGN_ENTITLEMENTS = DailySpeak/DailySpeak.Release.entitlements;' "$PBXPROJ"
rg -q 'com.apple.developer.applesignin' "$DEBUG_ENTITLEMENTS"
rg -q 'com.apple.developer.applesignin' "$RELEASE_ENTITLEMENTS"

echo "Checking root shell wiring..."
! rg -q 'TabView(selection: \$appState.selectedTab)' "$CONTENT_VIEW"
rg -q 'InitialAuthChoiceView' "$CONTENT_VIEW"
rg -q 'PersonalCenterView' "$CONTENT_VIEW"
rg -q 'NotificationsView' "$CONTENT_VIEW"
rg -q 'NavigationStack' "$CONTENT_VIEW"
! rg -q 'safeAreaInset\(edge: \.top' "$CONTENT_VIEW"
rg -q 'StageListView\(' "$CONTENT_VIEW"
rg -q 'showPersonalCenter' "$CONTENT_VIEW"
rg -q 'inboxNavigation\.openInbox()' "$CONTENT_VIEW"
rg -q 'navigationDestination\(isPresented: \$showPersonalCenter\)' "$CONTENT_VIEW"
! rg -q '\.sheet\(isPresented: \$showPersonalCenter\)' "$CONTENT_VIEW"
rg -q 'bell\.fill' "$ROOT/Views/StageListView.swift"
rg -q 'person\.crop\.circle\.fill' "$ROOT/Views/StageListView.swift"

echo "Checking ReSelf-style auth and shell screens..."
rg -q 'enum Step' "$AUTH_VIEW"
rg -q 'verifyStepView' "$AUTH_VIEW"
rg -q 'passwordStepView' "$AUTH_VIEW"
rg -q 'friendlyAppleSignInMessage' "$APP_AUTH"
rg -q 'navigationBarBackButtonHidden(true)' "$NOTIFICATIONS"
rg -q 'SettingsCard' "$PERSONAL_CENTER"
rg -q 'ProfileHeaderCard' "$PERSONAL_CENTER"
rg -q 'navigationTitle\("个人中心"\)' "$PERSONAL_CENTER"
rg -q 'SignInWithAppleButton' "$INITIAL_AUTH_VIEW"
rg -q 'NotificationService.shared.requestPermission' "$ROOT/Views/Shell/OnboardingView.swift"
rg -q 'PushNotificationService.shared.registerForRemoteNotificationsIfPossible' "$ROOT/Views/Shell/OnboardingView.swift"
rg -q 'guard oldValue, !newValue else' "$ROOT/DailySpeakApp.swift"
rg -q 'if !showOnboarding' "$ROOT/DailySpeakApp.swift"
rg -q 'authorization status:' "$PUSH_SERVICE"
rg -q 'currently registered for remote notifications' "$PUSH_SERVICE"
rg -q 'PushNotificationService.shared.registerForRemoteNotificationsIfPossible' "$ROOT/Views/Screens/NotificationSettingsView.swift"

echo "Checking direct OpenAI dependency removed from iOS shell..."
! rg -q 'api.openai.com' "$PRACTICE_AI"

echo "Checking backend contract matches verified server endpoints..."
rg -q '"translate/text"' "$API_SERVICE"
rg -q '"tts/english/mp3"' "$API_SERVICE"
rg -q '"sourceLang"' "$API_SERVICE"
rg -q '"targetLang"' "$API_SERVICE"
rg -q 'audioUrl' "$API_SERVICE"
! rg -q '"sourceLanguage"' "$API_SERVICE"
! rg -q '"targetLanguage"' "$API_SERVICE"
! rg -q '"scene"' "$API_SERVICE"
! rg -q '"topic"' "$API_SERVICE"
! rg -q '"dailyspeak/polish"' "$API_SERVICE"
rg -q 'requiresAuth: true' "$API_SERVICE"
rg -q 'requiresAuth: true' "$INBOX_SERVICE"
rg -q '"push/register"' "$PUSH_SERVICE"
rg -q '"environment"' "$PUSH_SERVICE"
rg -q '"deviceId"' "$PUSH_SERVICE"
rg -q '"pushEnabled"' "$PUSH_SERVICE"
rg -q 'message_id' "$PUSH_SERVICE"
rg -q 'mergeDuplicates' "$ROOT/Services/PushInboxStore.swift"
rg -q 'InboxDateParser' "$INBOX_SERVICE"
rg -q 'requiresAuth: true' "$PUSH_SERVICE"
rg -q 'registerForRemoteNotificationsIfPossible' "$PUSH_SERVICE"
rg -q 'Push token uploaded successfully' "$PUSH_SERVICE"
rg -q 'skip upload' "$PUSH_SERVICE"
rg -q 'Logger' "$PUSH_SERVICE"
rg -q 'logger\.' "$PUSH_SERVICE"
rg -q 'kSecClassGenericPassword' "$PUSH_SERVICE"
rg -q 'SecItemCopyMatching' "$PUSH_SERVICE"
rg -q 'SecItemUpdate' "$PUSH_SERVICE"
rg -q 'SecItemAdd' "$PUSH_SERVICE"
! rg -q 'identifierForVendor' "$PUSH_SERVICE"
rg -q 'waitsForConnectivity = true' "$WS_SERVICE"
rg -q '\[WS CONNECT\]' "$WS_SERVICE"
rg -q 'DispatchQueue\.main\.asyncAfter' "$WS_SERVICE"
rg -q '\[WS\] receive failed' "$WS_SERVICE"
rg -q 'AVPlayer' "$ENGLISH_SPEECH"
rg -q 'togglePlayback' "$ENGLISH_SPEECH"
rg -q 'playbackID' "$ENGLISH_SPEECH"
rg -q '\[TTS\] request english audio' "$ENGLISH_SPEECH"
rg -q '\[TTS\] english audio url ready' "$ENGLISH_SPEECH"
rg -q '\[TTS\] player item failed' "$ENGLISH_SPEECH"
! rg -q 'AVSpeechSynthesizer' "$ROOT/Views/LearningFlowView.swift"
! rg -q 'AVSpeechSynthesizer' "$ROOT/Views/PracticeView.swift"

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
rg -q 'private var centeredHeroCardWidth: CGFloat' "$OVERVIEW"
rg -q 'private var centeredHeroPromptBlock: some View' "$OVERVIEW"
rg -q '\.frame\(width: centeredHeroCardWidth, alignment: \.leading\)' "$OVERVIEW"
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
