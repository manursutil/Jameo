//
//  PromptTextField.swift
//  Jameo
//
//  Created by Manuel Rodríguez Sutil on 13/06/2026.
//

import AppKit
import SwiftUI

struct PromptTextField: NSViewRepresentable {
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
        textField.placeholderString = placeholder

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
