//
//  ContentView.swift
//  spoken englist
//
//  Created by levi on 2026/2/28.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    private let previewStage = CourseData.stages[0]
    private var previewTask: SpeakingTask { previewStage.tasks[0] }
    private let arguments = ProcessInfo.processInfo.arguments
    @State private var showSettings = false
    @State private var hasReportedLaunch = false

    private var previewStrategyView: some View {
        ScrollView(showsIndicators: false) {
            StrategyStepView(task: previewTask, accentColor: previewStage.theme.startColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("答题策略")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewFrameworkView: some View {
        ScrollView(showsIndicators: false) {
            FrameworkStepView(task: previewTask, accentColor: previewStage.theme.startColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("表达框架")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var previewPracticeView: some View {
        ScrollView(showsIndicators: false) {
            PracticePromptView(stageId: previewStage.id, task: previewTask, accentColor: previewStage.theme.startColor)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
        }
        .background(AppColors.background.ignoresSafeArea())
        .navigationTitle("口语练习")
        .navigationBarTitleDisplayMode(.inline)
    }

    var body: some View {
        Group {
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
            } else if appState.shouldShowOnboarding {
                OnboardingView {
                    appState.completeOnboarding()
                }
            } else if appState.shouldShowAuthChoice {
                AuthChoiceView()
            } else {
                ZStack(alignment: .topTrailing) {
                    StageListView()

                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(AppColors.primaryText)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.92), in: Circle())
                            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .padding(.trailing, 20)
                }
                .sheet(isPresented: $showSettings) {
                    NavigationStack {
                        SettingsView()
                    }
                    .presentationBackground(AppColors.background)
                }
            }
        }
        .task {
            guard !hasReportedLaunch else { return }
            hasReportedLaunch = true
            AppEventReporter.shared.report(.appLaunch)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(ProgressManager())
}
