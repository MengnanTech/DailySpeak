#!/bin/bash
set -e

# Task 2, Step 1: settings/profile shell updates
rg --fixed-strings '.modifier(AppCardStyle())' DailySpeak/Views/Screens/PersonalCenterView.swift
rg --fixed-strings 'struct SettingsSection<Content: View>: View' DailySpeak/Views/Components/SettingsComponents.swift
rg --fixed-strings '.background(Color.appBackground.edgesIgnoringSafeArea(.all))' DailySpeak/Views/Screens/AppSettingsView.swift

# Task 2, Step 2: onboarding and splash motion updates
rg --fixed-strings 'OnboardingPage(title: "Practice Speaking",' DailySpeak/Views/Shell/OnboardingView.swift
rg --fixed-strings 'let splashAnimation = SplashAnimation(animation: .RIVE_SPLASH_V2, fit: .fitWidth)' DailySpeak/Views/Shell/SplashAnimationView.swift

# Task 2, Step 3: stage-list header polish
rg --fixed-strings 'small' DailySpeak/Views/StageListView.swift | rg --fixed-strings 'Stats'

# Task 2, Step 4: vocabulary icon cleanup
rg --fixed-strings '.filter { $0.category != .all }' DailySpeak/Models/CourseData.swift
rg --fixed-strings 'case .vocabulary: return "text.book.closed"' DailySpeak/Views/LearningFlowView.swift
