//
//  JameoViewModel.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Combine
import Foundation

@MainActor
final class JameoViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var answer: String = ""
    @Published var isLoading: Bool = false
    @Published var focusRequest = UUID()
    @Published var screenContextEnabled: Bool = false
    @Published private(set) var screenContextAvailable: Bool = false
    @Published private(set) var isCheckingScreenContextAvailability: Bool = false
    @Published private(set) var didSubmitWithScreenContext: Bool = false

    private var generationTask: Task<Void, Never>?
    private var availabilityTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    var screenContextImageProvider: (() async throws -> Data?)?

    init() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshScreenContextAvailability()
            }
            .store(in: &cancellables)

        refreshScreenContextAvailability()
    }

    func requestFocus() {
        focusRequest = UUID()
    }

    func reset() {
        generationTask?.cancel()
        generationTask = nil
        prompt = ""
        answer = ""
        isLoading = false
        didSubmitWithScreenContext = false
    }

    func askJameo() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let shouldIncludeScreenContext = screenContextEnabled
        guard !isLoading, !submittedPrompt.isEmpty || shouldIncludeScreenContext else { return }

        generationTask = Task {
            isLoading = true
            answer = ""
            didSubmitWithScreenContext = false

            var screenImages: [Data]?

            if shouldIncludeScreenContext {
                do {
                    guard try await OllamaService.shared.selectedModelSupportsVision() else {
                        screenContextAvailable = false
                        screenContextEnabled = false
                        answer = String(localized: "The selected model does not support screen context.")
                        isLoading = false
                        generationTask = nil
                        return
                    }

                    guard let screenImage = try await screenContextImageProvider?() else {
                        answer = String(localized: "Could not capture the current screen.")
                        isLoading = false
                        generationTask = nil
                        return
                    }

                    screenImages = [screenImage]
                } catch {
                    guard !Task.isCancelled else { return }
                    answer = error.localizedDescription
                    isLoading = false
                    generationTask = nil
                    return
                }
            }

            do {
                let stream = OllamaService.shared.generateStream(
                    prompt: submittedPrompt.isEmpty ? String(localized: "Help me understand what is on my screen.") : submittedPrompt,
                    images: screenImages
                )

                didSubmitWithScreenContext = screenImages != nil

                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    answer += chunk
                }

                if didSubmitWithScreenContext {
                    screenContextEnabled = false
                }
            } catch {
                guard !Task.isCancelled else { return }
                answer = "Error: \(error)"
            }

            isLoading = false
            generationTask = nil
        }
    }

    func refreshScreenContextAvailability() {
        availabilityTask?.cancel()

        availabilityTask = Task {
            isCheckingScreenContextAvailability = true

            do {
                screenContextAvailable = try await OllamaService.shared.selectedModelSupportsVision()
            } catch {
                guard !Task.isCancelled else { return }
                screenContextAvailable = false
            }

            if !screenContextAvailable {
                screenContextEnabled = false
            }

            isCheckingScreenContextAvailability = false
            availabilityTask = nil
        }
    }
}
