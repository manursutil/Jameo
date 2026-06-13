//
//  Ollama.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Ollama
import Foundation

class OllamaService {
    static let shared = OllamaService()
    
    private let client = Client(
        host: URL(string: "http://127.0.0.1:11434")!,
        userAgent: "Jameo/1.0"
    )
    
    private let systemPrompt = """
    You are a concise assistant. Reply in the same language as the user's request unless they explicitly ask for another language. Match the answer length to the question: for simple factual questions, answer in one short sentence or line; for definitions or simple clarifications, use one short paragraph; use 2-3 short paragraphs only when explaining a concept, tradeoff, process, or when the user asks for more detail. Answer directly. Avoid preambles, summaries, repeated warnings, and unnecessary context. Use lists only when they make the answer shorter. If code is needed, provide the smallest functional snippet.
    """
    
    private init() {}
    
    func generateStream(prompt: String, images: [Data]? = nil) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = try client.chatStream(
                        model: selectedModel,
                        messages: [
                            .system(systemPrompt),
                            .user(prompt, images: images),
                        ],
                        options: [
                            "temperature": 0.7,
                            "num_predict": 1024,
                        ],
                        think: JameoSettings.reasoningEnabled,
                        keepAlive: .minutes(10)
                    )

                    for try await chunk in stream {
                        continuation.yield(chunk.message.content)
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func selectedModelSupportsVision() async throws -> Bool {
        let response = try await client.showModel(selectedModel)

        return response.capabilities.contains(.vision)
    }

    func localModelNames() async throws -> [String] {
        let response = try await client.listModels()

        return response.models
            .map(\.name)
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var selectedModel: Model.ID {
        Model.ID(rawValue: JameoSettings.model) ?? Model.ID(rawValue: JameoSettings.defaultModel)!
    }
}
