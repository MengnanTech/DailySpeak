import Foundation
import SwiftUI

@Observable
final class ProgressManager {
    private let defaults = UserDefaults.standard
    private let stepsKey = "completedSteps"
    private let tasksKey = "completedTasks"
    private let activityDaysKey = "learningActivityDays"
    private let taskCompletionDatesKey = "taskCompletionDates"

    private(set) var completedSteps: Set<String>
    private(set) var completedTasks: Set<String>
    private(set) var learningActivityDays: Set<String>
    private(set) var taskCompletionDates: [String: String]

    init() {
        let steps = UserDefaults.standard.stringArray(forKey: "completedSteps") ?? []
        let tasks = UserDefaults.standard.stringArray(forKey: "completedTasks") ?? []
        let activityDays = UserDefaults.standard.stringArray(forKey: "learningActivityDays") ?? []
        let completionDates = UserDefaults.standard.dictionary(forKey: "taskCompletionDates") as? [String: String] ?? [:]
        self.completedSteps = Set(steps)
        self.completedTasks = Set(tasks)
        self.learningActivityDays = Set(activityDays)
        self.taskCompletionDates = completionDates
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

    func isTaskUnlocked(stageId: Int, taskId: Int, in stage: Stage) -> Bool {
        // All tasks within an unlocked stage are accessible in any order
        return isStageUnlocked(stageId: stageId)
    }

    // MARK: - Stage Progress

    func isStageCompleted(_ stage: Stage) -> Bool {
        stage.tasks.allSatisfy { isTaskCompleted(stageId: stage.id, taskId: $0.id) }
    }

    func isStageUnlocked(stageId: Int) -> Bool {
        if stageId == 1 { return true }
        // Previous stage must be fully completed
        let stages = CourseData.stages
        guard let prevStage = stages.first(where: { $0.id == stageId - 1 }) else { return false }
        return isStageCompleted(prevStage)
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

    // MARK: - Persistence
    private func save() {
        defaults.set(Array(completedSteps), forKey: stepsKey)
        defaults.set(Array(completedTasks), forKey: tasksKey)
        defaults.set(Array(learningActivityDays), forKey: activityDaysKey)
        defaults.set(taskCompletionDates, forKey: taskCompletionDatesKey)
    }

    func resetAll() {
        completedSteps.removeAll()
        completedTasks.removeAll()
        learningActivityDays.removeAll()
        taskCompletionDates.removeAll()
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
