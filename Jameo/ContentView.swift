//
//  ContentView.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: JameoViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button {
                    viewModel.screenContextEnabled.toggle()
                } label: {
                    Image(systemName: "display")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(viewModel.screenContextEnabled ? .primary : .secondary)
                .background {
                    if viewModel.screenContextEnabled {
                        Circle()
                            .fill(Color.secondary.opacity(0.16))
                    }
                }
                .help(screenContextHelp)
                .disabled(viewModel.isLoading || viewModel.isCheckingScreenContextAvailability || !viewModel.screenContextAvailable)

                PromptTextField(
                    text: $viewModel.prompt,
                    placeholder: promptPlaceholder,
                    focusRequest: viewModel.focusRequest
                ) {
                    viewModel.askJameo()
                }
                .frame(height: 30)

                Button {
                    viewModel.askJameo()
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
                .disabled(isSubmitDisabled)
            }

            if viewModel.didSubmitWithScreenContext {
                Label("Screen included", systemImage: "display")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: viewModel.answer, options: options)) ?? AttributedString(viewModel.answer)
    }

    private var isSubmitDisabled: Bool {
        viewModel.isLoading || (viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.screenContextEnabled)
    }

    private var promptPlaceholder: String {
        viewModel.screenContextEnabled ? String(localized: "Ask about your screen...") : String(localized: "Ask Jameo...")
    }

    private var screenContextHelp: String {
        if viewModel.isCheckingScreenContextAvailability {
            return String(localized: "Checking screen context availability...")
        }

        if !viewModel.screenContextAvailable {
            return String(localized: "The selected model does not support screen context.")
        }

        return String(localized: "Include current screen with the next question")
    }
}

#Preview {
    ContentView(viewModel: JameoViewModel())
}
