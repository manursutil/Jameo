//
//  ContentView.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var answer: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Ask Luma...", text: $prompt)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .submitLabel(.send)
                    .onSubmit {
                        askLuma()
                    }

                Button {
                    askLuma()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.black)
                .keyboardShortcut(.defaultAction)
                .disabled(isLoading || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if isLoading {
                ProgressView()
            }

            if !answer.isEmpty {
                Divider()
                Text(answer)
                    .textSelection(.enabled)
            }
        }
        .padding()
        .frame(width: 700)
    }
    
    private func askLuma() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty, !isLoading else { return }

        Task {
            isLoading = true
            answer = ""
            
            do {
                let stream = OllamaService.shared.generateStream(prompt: submittedPrompt)

                for try await chunk in stream {
                    answer += chunk
                }
            } catch {
                answer = "Error \(error)"
            }
            
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
