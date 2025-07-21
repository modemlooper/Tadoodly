//
//  IntelligenceModel.swift
//  Tadoodly
//
//  Created by modemlooper on 6/28/25.
//

import SwiftUI

#if canImport(FoundationModels)
import FoundationModels


@available(iOS 26.0, *)
@MainActor
final class ProjectPlanner {
    
    @EnvironmentObject var model: ProjectPlannerViewModel
    
    private var session: LanguageModelSession
    
    private var plan: Planner.PartiallyGenerated?
    
    init() {
        self.session = LanguageModelSession(
            instructions: "You are an expert project planner and will assist the user with their project by creating tasks"
        )
    }
    
    func generate(for project: Project) -> AsyncThrowingStream<Planner.PartiallyGenerated, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let prompt = "I want to create a project. Use this to formulate a response: '\(project.name)' with the following description: \(project.projectDescription). Please generate a task list."
                    let response = session.streamResponse(
                        to: prompt,
                        generating: Planner.self,
                        options: GenerationOptions(sampling: .greedy)
                    )
                    for try await partial in response {
                        continuation.yield(partial)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Generates a new task using the language model and appends it to model.tasks
    func addTask() async {
        guard !model.title.isEmpty else { return }
        let prompt = "Generate one new actionable task for the project titled '\(model.title)' with description: \(model.description). Return just the task text."
        do {
            let response = try await session.respond(
                to: prompt,
                generating: String.self
            )
            await MainActor.run {
                model.tasks.append(response.content)
            }
        } catch {
            await MainActor.run {
                model.errorMessage = "Failed to generate a new task. Please try again."
                model.showErrorAlert = true
            }
        }
    }
    
}

@available(iOS 26.0, *)
func isFoundationModelAvailable() -> Bool {
    
    let model = SystemLanguageModel.default
    
    switch model.availability {
        case .available:
            return true
        case .unavailable(.appleIntelligenceNotEnabled):
            return false
        case .unavailable(.modelNotReady):
            return false
        case .unavailable(.deviceNotEligible):
            return false
        default:
            return false
    }
}
#endif
