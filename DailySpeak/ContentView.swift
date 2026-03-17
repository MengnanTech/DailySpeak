//
//  ContentView.swift
//  spoken englist
//
//  Created by levi on 2026/2/28.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var inboxNavigation = InboxNavigationCoordinator.shared
    @State private var showPersonalCenter = false
    private let previewStage = CourseData.stages[0]
    private var previewTask: SpeakingTask { previewStage.tasks[0] }
    private let arguments = ProcessInfo.processInfo.arguments

    @State private var previewCanComplete = false
    @State private var previewProgressHint: String? = nil

    private var previewStrategyView: some View {
        ScrollView(showsIndicators: false) {
            StrategyStepView(stageId: previewStage.id, task: previewTask, accentColor: previewStage.theme.startColor, canComplete: $previewCanComplete, progressHint: $previewProgressHint)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Answer Strategy")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewFrameworkView: some View {
        ScrollView(showsIndicators: false) {
            FrameworkStepView(stageId: previewStage.id, task: previewTask, accentColor: previewStage.theme.startColor, canComplete: $previewCanComplete, progressHint: $previewProgressHint)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Expression Framework")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewPracticeView: some View {
        ScrollView(showsIndicators: false) {
            PracticePromptView(stageId: previewStage.id, task: previewTask, accentColor: previewStage.theme.startColor, canComplete: $previewCanComplete, progressHint: $previewProgressHint)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("Speaking Practice")
        .navigationBarTitleDisplayMode(.inline)
    }

    var body: some View {
        if arguments.contains("--preview-q01-learning") {
            NavigationStack {
                LearningFlowView(stage: previewStage, task: previewTask)
            }
        } else if arguments.contains("--preview-q01-strategy") {
            NavigationStack { previewStrategyView }
        } else if arguments.contains("--preview-q01-framework") {
            NavigationStack { previewFrameworkView }
        } else if arguments.contains("--preview-q01-practice") {
            NavigationStack { previewPracticeView }
        } else if arguments.contains("--preview-q01-overview") {
            NavigationStack {
                TaskOverviewView(stage: previewStage, task: previewTask)
            }
        } else {
            NavigationStack {
                StageListView(
                    unreadCount: appState.unreadNotificationCount,
                    onProfileTap: { showPersonalCenter = true },
                    onInboxTap: { inboxNavigation.openInbox() }
                )
                    .navigationDestination(isPresented: $showPersonalCenter) {
                        PersonalCenterView()
                            .environmentObject(appState)
                    }
                    .fullScreenCover(
                        isPresented: Binding(
                            get: { appState.shouldShowInitialAuthChoice },
                            set: { _ in }
                        )
                    ) {
                        InitialAuthChoiceView()
                            .environmentObject(appState)
                            .interactiveDismissDisabled()
                    }
                    .sheet(isPresented: $inboxNavigation.shouldPresentInbox) {
                        NavigationStack {
                            NotificationsView()
                                .environmentObject(appState)
                        }
                    }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environment(ProgressManager())
        .environment(SubscriptionManager())
}
