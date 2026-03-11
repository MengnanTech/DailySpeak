//
//  DailySpeakApp.swift
//  DailySpeak
//
//  Created by levi on 2026/2/28.
//

import SwiftUI
import UIKit

@main
struct DailySpeakApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var progressManager = ProgressManager()
    @StateObject private var appState = AppState()
    @State private var showSplash = true
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if showOnboarding {
                        OnboardingView(isPresented: $showOnboarding)
                    } else {
                        ContentView()
                            .environment(progressManager)
                            .environmentObject(appState)
                    }
                }

                if showSplash {
                    SplashAnimationView {
                        showSplash = false
                    }
                    .zIndex(1)
                    .transition(.opacity)
                }
            }
            .onAppear {
                checkFirstLaunch()
                appState.startRuntimeServices()
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    appState.startRuntimeServices()
                case .inactive, .background:
                    appState.stopRuntimeServices()
                @unknown default:
                    break
                }
            }
        }
    }

    private func checkFirstLaunch() {
        let defaults = UserDefaults.standard
        let hasLaunchedBefore = defaults.bool(forKey: Constants.StorageKeys.hasLaunchedBefore)
        if !hasLaunchedBefore {
            showOnboarding = true
            defaults.set(true, forKey: Constants.StorageKeys.hasLaunchedBefore)
        }
    }
}
