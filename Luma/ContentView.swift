//
//  ContentView.swift
//  Luma
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import Combine
import AppKit
import SwiftUI

@MainActor
final class LumaViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var answer: String = ""
    @Published var isLoading: Bool = false
    @Published var focusRequest = UUID()
    private var generationTask: Task<Void, Never>?

    func requestFocus() {
        focusRequest = UUID()
    }

    func reset() {
        generationTask?.cancel()
        generationTask = nil
        prompt = ""
        answer = ""
        isLoading = false
    }

    func askLuma() {
        let submittedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !submittedPrompt.isEmpty, !isLoading else { return }

        generationTask = Task {
            isLoading = true
            answer = ""

            do {
                let stream = OllamaService.shared.generateStream(prompt: submittedPrompt)

                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    answer += chunk
                }
            } catch {
                guard !Task.isCancelled else { return }
                answer = "Error \(error)"
            }

            isLoading = false
            generationTask = nil
        }
    }
}

struct ContentView: View {
    @ObservedObject var viewModel: LumaViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                PromptTextField(
                    text: $viewModel.prompt,
                    placeholder: "Ask Luma...",
                    focusRequest: viewModel.focusRequest
                ) {
                        viewModel.askLuma()
                }
                .frame(height: 30)

                Button {
                    viewModel.askLuma()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.circle)
                .tint(.black)
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isLoading || viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if viewModel.isLoading {
                Text("Thinking...")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !viewModel.answer.isEmpty {
                Divider()
                ScrollView {
                    Text(renderedAnswer)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 620, alignment: .topLeading)
    }

    private var renderedAnswer: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
        return (try? AttributedString(markdown: viewModel.answer, options: options)) ?? AttributedString(viewModel.answer)
    }
}

#Preview {
    ContentView(viewModel: LumaViewModel())
}

private struct PromptTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let focusRequest: UUID
    let onSubmit: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.delegate = context.coordinator
        textField.placeholderString = placeholder
        textField.font = .systemFont(ofSize: 18)
        textField.isBordered = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.focusRingType = .none
        textField.lineBreakMode = .byTruncatingTail
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.submit)
        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        context.coordinator.parent = self

        if textField.stringValue != text {
            textField.stringValue = text
        }

        guard context.coordinator.lastFocusRequest != focusRequest else { return }

        context.coordinator.lastFocusRequest = focusRequest
        DispatchQueue.main.async {
            textField.window?.makeFirstResponder(textField)
            textField.currentEditor()?.selectedRange = NSRange(location: textField.stringValue.count, length: 0)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: PromptTextField
        var lastFocusRequest: UUID?

        init(parent: PromptTextField) {
            self.parent = parent
        }

        @objc func submit() {
            parent.onSubmit()
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else { return }
            parent.text = textField.stringValue
        }
    }
}
