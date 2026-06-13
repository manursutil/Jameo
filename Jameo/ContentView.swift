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
                PromptTextField(
                    text: $viewModel.prompt,
                    placeholder: String(localized: "Ask Jameo..."),
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
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: viewModel.answer, options: options)) ?? AttributedString(viewModel.answer)
    }
}

#Preview {
    ContentView(viewModel: JameoViewModel())
}
