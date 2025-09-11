// ProjectPlannerViewModel.swift
// Extracts the state from ModelView for persistence across sheet presentations.

import SwiftUI
#if canImport(FoundationModels)
import FoundationModels


@available(iOS 26.0, *)
@Observable
class ProjectPlannerViewModel {
    var partialPlans: [Planner.PartiallyGenerated] = []
    
    var title: String = ""
    var description: String = ""
    var tasks: [String] = []
    
    var inputText: String = ""
    var isInputDisabled: Bool = false
    var isCreateDisabled: Bool = true
    
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    
    var showInfoPopup: Bool = false
    var latestInfoMessage: String = ""
    
    var borderAnimationPhase: Double = 0
    var borderAnimationTimer: Timer? = nil
    
    var isGenerating: Bool = false
    
    var buttonBorderAnimationPhase: Double = 0
    var buttonBorderAnimationTimer: Timer? = nil
    
    init() { }
    
    func addTask() async {
        guard !title.isEmpty else { return }
        let tasksList = tasks.isEmpty ? "(No tasks yet)" : tasks.enumerated().map { "\($0 + 1). \($1)" }.joined(separator: "\n")
        let prompt = "Generate one new actionable task for the project titled '\(title)' with description: \(description). Current tasks are:\n\(tasksList)\nReturn just the task text. Do not repeat a previous task."
        do {
            let session = LanguageModelSession()
            // For single-shot generation, request a String and use response.content.
            let response = try await session.respond(
                to: prompt,
                generating: additonalTask.self
            )
            print(response.content.name)
            tasks.append(response.content.name)
        } catch {
            errorMessage = "Failed to generate a new task. Please try again."
            showErrorAlert = true
        }
    }
}
#endif
