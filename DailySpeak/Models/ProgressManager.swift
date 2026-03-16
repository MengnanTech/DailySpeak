import Foundation
import SwiftUI

@Observable
final class ProgressManager {
    private let defaults = UserDefaults.standard
    private let stepsKey = "completedSteps"
    private let tasksKey = "completedTasks"
    private let activityDaysKey = "learningActivityDays"
    private let taskCompletionDatesKey = "taskCompletionDates"
    private let studyTimeKey = "dailyStudySeconds"
    private let guidesKey = "completedGuides"

    private(set) var completedSteps: Set<String>
    private(set) var completedTasks: Set<String>
    private(set) var learningActivityDays: Set<String>
    private(set) var taskCompletionDates: [String: String]
    /// Daily study seconds: ["2026-03-14": 1234.5]
    private(set) var dailyStudySeconds: [String: Double]
    private(set) var completedGuides: Set<String>

    // Active session tracking
    private var sessionStartTime: Date?

    init() {
        let steps = UserDefaults.standard.stringArray(forKey: "completedSteps") ?? []
        let tasks = UserDefaults.standard.stringArray(forKey: "completedTasks") ?? []
        let activityDays = UserDefaults.standard.stringArray(forKey: "learningActivityDays") ?? []
        let completionDates = UserDefaults.standard.dictionary(forKey: "taskCompletionDates") as? [String: String] ?? [:]
        let studyTime = UserDefaults.standard.dictionary(forKey: "dailyStudySeconds") as? [String: Double] ?? [:]
        let guides = UserDefaults.standard.stringArray(forKey: "completedGuides") ?? []
        self.completedSteps = Set(steps)
        self.completedTasks = Set(tasks)
        self.learningActivityDays = Set(activityDays)
        self.taskCompletionDates = completionDates
        self.dailyStudySeconds = studyTime
        self.completedGuides = Set(guides)
    }

    // MARK: - Step Progress
    private func stepKey(_ stageId: Int, _ taskId: Int, _ stepIndex: Int) -> String {
        "s\(stageId)_t\(taskId)_step\(stepIndex)"
    }

    func isStepCompleted(stageId: Int, taskId: Int, stepIndex: Int) -> Bool {
        completedSteps.contains(stepKey(stageId, taskId, stepIndex))
    }

    func completeStep(stageId: Int, taskId: Int, stepIndex: Int) {
        let key = stepKey(stageId, taskId, stepIndex)
        completedSteps.insert(key)
        save()
    }

    func completedStepCount(stageId: Int, taskId: Int, totalSteps: Int) -> Int {
        (0..<totalSteps).filter { isStepCompleted(stageId: stageId, taskId: taskId, stepIndex: $0) }.count
    }

    func currentStepIndex(stageId: Int, taskId: Int, totalSteps: Int) -> Int {
        for i in 0..<totalSteps {
            if !isStepCompleted(stageId: stageId, taskId: taskId, stepIndex: i) { return i }
        }
        return totalSteps
    }

    // MARK: - Task Progress
    private func taskKey(_ stageId: Int, _ taskId: Int) -> String {
        "s\(stageId)_t\(taskId)"
    }

    func isTaskCompleted(stageId: Int, taskId: Int) -> Bool {
        completedTasks.contains(taskKey(stageId, taskId))
    }

    func completeTask(stageId: Int, taskId: Int) {
        let key = taskKey(stageId, taskId)
        let isNewCompletion = completedTasks.insert(key).inserted
        if isNewCompletion {
            let todayKey = dayKey(for: Date())
            learningActivityDays.insert(todayKey)
            taskCompletionDates[key] = todayKey
        }
        save()
    }

    func completedTaskCount(for stage: Stage) -> Int {
        stage.tasks.filter { isTaskCompleted(stageId: stage.id, taskId: $0.id) }.count
    }

    func stageProgress(for stage: Stage) -> Double {
        guard stage.taskCount > 0 else { return 0 }
        return Double(completedTaskCount(for: stage)) / Double(stage.taskCount)
    }

    func isTaskUnlocked(stageId: Int, taskId: Int, in stage: Stage, subscription: SubscriptionManager) -> Bool {
        return isStageUnlocked(stageId: stageId, subscription: subscription)
    }

    // MARK: - Stage Progress

    func isStageCompleted(_ stage: Stage) -> Bool {
        stage.tasks.allSatisfy { isTaskCompleted(stageId: stage.id, taskId: $0.id) }
    }

    /// Stage is unlocked if: stage 1 (free), or subscription active, or stage individually purchased
    func isStageUnlocked(stageId: Int, subscription: SubscriptionManager) -> Bool {
        if stageId == 1 { return true }
        return subscription.isStageAccessible(stageId)
    }

    /// Whether a stage needs payment (not accessible via subscription or purchase)
    func isStageLocked(stageId: Int, subscription: SubscriptionManager) -> Bool {
        stageId > 1 && !subscription.isStageAccessible(stageId)
    }

    // MARK: - Guide Completion
    private func guideKey(_ stageId: Int, _ taskId: Int, _ guideName: String) -> String {
        "s\(stageId)_t\(taskId)_\(guideName)"
    }

    func isGuideCompleted(stageId: Int, taskId: Int, guideName: String) -> Bool {
        completedGuides.contains(guideKey(stageId, taskId, guideName))
    }

    func completeGuide(stageId: Int, taskId: Int, guideName: String) {
        completedGuides.insert(guideKey(stageId, taskId, guideName))
        save()
    }

    // MARK: - Daily Motivation
    func todayCompletedTaskCount(referenceDate: Date = Date()) -> Int {
        let key = dayKey(for: referenceDate)
        return taskCompletionDates.values.filter { $0 == key }.count
    }

    func currentStreakDays(referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: referenceDate)
        var streak = 0

        while learningActivityDays.contains(dayKey(for: day)) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }

        return streak
    }

    func recommendedDailyGoal() -> Int {
        3
    }

    func hasMetDailyGoal(referenceDate: Date = Date()) -> Bool {
        todayCompletedTaskCount(referenceDate: referenceDate) >= recommendedDailyGoal()
    }

    func dailyGoalRemaining(referenceDate: Date = Date()) -> Int {
        max(0, recommendedDailyGoal() - todayCompletedTaskCount(referenceDate: referenceDate))
    }

    // MARK: - Study Time Tracking

    /// Call when a learning session begins (e.g. LearningFlowView appears)
    func startStudySession() {
        sessionStartTime = Date()
    }

    /// Call when a learning session ends (e.g. LearningFlowView disappears)
    func endStudySession() {
        guard let start = sessionStartTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        sessionStartTime = nil
        // Only count sessions > 3 seconds (filter accidental opens)
        guard elapsed > 3 else { return }
        let key = dayKey(for: Date())
        dailyStudySeconds[key, default: 0] += elapsed
        learningActivityDays.insert(key)
        save()
    }

    /// Today's study time in seconds
    func todayStudySeconds(referenceDate: Date = Date()) -> Double {
        dailyStudySeconds[dayKey(for: referenceDate)] ?? 0
    }

    /// Total study time across all days in seconds
    func totalStudySeconds() -> Double {
        dailyStudySeconds.values.reduce(0, +)
    }

    /// Formatted study time string, e.g. "12 min" or "1h 23min"
    static func formatStudyTime(seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        if totalMinutes < 1 { return "<1 min" }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)min" : "\(hours)h"
        }
        return "\(mins) min"
    }

    // MARK: - Persistence
    private func save() {
        defaults.set(Array(completedSteps), forKey: stepsKey)
        defaults.set(Array(completedTasks), forKey: tasksKey)
        defaults.set(Array(learningActivityDays), forKey: activityDaysKey)
        defaults.set(taskCompletionDates, forKey: taskCompletionDatesKey)
        defaults.set(dailyStudySeconds, forKey: studyTimeKey)
        defaults.set(Array(completedGuides), forKey: guidesKey)
    }

    func resetAll() {
        completedSteps.removeAll()
        completedTasks.removeAll()
        learningActivityDays.removeAll()
        taskCompletionDates.removeAll()
        dailyStudySeconds.removeAll()
        completedGuides.removeAll()
        save()
    }

    private func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
