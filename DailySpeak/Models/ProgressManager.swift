import Foundation
import SwiftUI

@Observable
final class ProgressManager {
    private let defaults = UserDefaults.standard
    private let stepsKey = "completedSteps"
    private let tasksKey = "completedTasks"

    private(set) var completedSteps: Set<String>
    private(set) var completedTasks: Set<String>

    init() {
        let steps = UserDefaults.standard.stringArray(forKey: "completedSteps") ?? []
        let tasks = UserDefaults.standard.stringArray(forKey: "completedTasks") ?? []
        self.completedSteps = Set(steps)
        self.completedTasks = Set(tasks)
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
        completedTasks.insert(taskKey(stageId, taskId))
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
        if taskId == 1 { return true }
        return isTaskCompleted(stageId: stageId, taskId: taskId - 1)
    }

    // MARK: - Persistence
    private func save() {
        defaults.set(Array(completedSteps), forKey: stepsKey)
        defaults.set(Array(completedTasks), forKey: tasksKey)
    }

    func resetAll() {
        completedSteps.removeAll()
        completedTasks.removeAll()
        save()
    }
}
