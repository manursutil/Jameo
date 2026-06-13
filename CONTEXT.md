# Jameo Context

## Language

**Current-screen context**:
Visual information from the display containing the Jameo panel when the user submits a question with screen context enabled. It means screenshot-like visual context, not app-specific text extraction or automatic screen watching.
_Avoid_: automatic screen watching, OCR-only context, semantic app context, window-only context

**Screen-context toggle**:
A compact control in the prompt bar that arms current-screen context for the next submitted question. Turning it on does not capture immediately; the screen is captured at submit time, then the toggle resets to off after a successful submission and stays on for retryable failures.
_Avoid_: capture-now button, persistent screen recording

**Screen-included confirmation**:
A lightweight text/icon confirmation that a submitted question included current-screen context. It is not a thumbnail, blocking screenshot preview, or confirmation dialog.
_Avoid_: screenshot thumbnail, blocking preview, confirmation dialog

**Screen image**:
The captured image of the active display sent with a screen-context question, downscaled for model input rather than sent at full display resolution. The first version should use a fixed maximum long edge around 1600 px rather than a user-facing setting. Jameo hides its own panel before capture so the screen image represents the user's workspace rather than Jameo itself, then shows the panel again immediately while the answer streams. The image is kept only in memory for the request and is not written to disk, logs, or history.
_Avoid_: OCR transcript, generated screen summary, persisted screenshot

**Preserved screen-context result**:
A screen-context answer whose prompt and response text may remain visible between panel opens when preservation is enabled. The captured screen image itself is never preserved, and preserved text is display state rather than context for a follow-up conversation.
_Avoid_: screenshot history, preserved screen image, follow-up context

**Screen-only question**:
A submitted question with screen context enabled and no user-entered prompt text. It asks Jameo to respond based on the captured screen image alone, using a neutral default intent such as "Help me understand what is on my screen."
_Avoid_: requiring prompt text for screen-context submissions

**Vision-capable model**:
An Ollama model that can accept a screen image as input. Screen context is only available when the selected model is vision-capable.
_Avoid_: OCR fallback for text-only models, silently dropping screen images

**Screen-context availability**:
Whether screen context can be used with the currently selected model. Jameo should determine this from model capability metadata for UI state and re-check it before sending a screen-context question; when unavailable, the screen-context toggle remains visible but disabled.
_Avoid_: hidden capability, UI-only validation, submit-only validation

**Screen-context submission**:
A one-shot Jameo submission that includes current-screen context. It cannot be started while another answer is streaming.
_Avoid_: overlapping screen-context requests, multi-message screen chat

## Product Direction

Jameo is a native macOS utility for asking a local Ollama model quick one-shot questions from anywhere in the system.

The intended user experience is closer to macOS Spotlight than a conventional windowed app. Jameo should live quietly in the background, be available globally through a keyboard shortcut, and avoid requiring the user to manage a normal app window.

## Current App Shape

- Native SwiftUI macOS app.
- Current UI is a simple prompt field plus streamed answer.
- UI text is localized with an English source language and Spanish translations, following the user's system language.
- Current Ollama integration is one-shot prompt generation through `OllamaService`.
- Model name, reasoning behavior, and panel state preservation are configurable in settings.
- The assistant prompt asks the model to respond in the same language as the user's request unless the user asks for another language.

## First Milestone

The first priority is turning the existing core functionality into a Spotlight-like macOS background utility.

Decisions:

- Jameo should be a menu-bar/background app, not a conventional Dock-window app.
- It should expose a menu bar icon.
- The menu bar icon should open a compact Ollama-style menu with `Open Jameo`, `Settings...`, a separator, and `Quit Jameo`.
- Pressing `Cmd+Shift+Space` should show a floating Spotlight-style bar/panel.
- Pressing `Cmd+Shift+Space` again while the panel is visible should toggle it closed.
- The implementation should use built-in macOS/AppKit APIs where practical.
- Avoid external dependencies unless the built-in approach becomes significantly harder or less reliable.
- For the first version, use a fixed built-in global hotkey implementation rather than adding a package for configurable shortcuts.
- The panel should hide when it loses focus.
- The panel should start empty every time it opens.
- Pressing `Esc` should close the panel.
- When opened, the prompt should be focused so the user can type immediately.
- The first version should keep the current one-shot prompt plus streamed answer flow.
- The assistant should answer in the user's language by default.
- Do not turn the panel into a multi-message chat yet.

## Future Settings

Settings should be reachable from the menu bar icon.

Likely settings:

- Model selection.
- Reasoning on/off.
- Preserve prompt and answer between panel opens.
- More UI languages beyond English and Spanish.
- Possibly whether the panel hides on focus loss.
- Eventually, configurable global shortcut.

## Future Context Awareness

A future direction is for Jameo to take context from the current screen. This is not part of the first milestone.

This likely needs separate design work because it may affect:

- macOS permissions.
- Privacy expectations.
- Whether context is captured automatically or only by explicit user action.
- How captured context is shown to the user before being sent to a model.

## Implementation Bias

Prefer a small native implementation that matches macOS conventions:

- AppKit/SwiftUI interop is acceptable for window, panel, menu bar, and hotkey behavior.
- Keep the first slice narrow and shippable.
- Defer settings and current-screen context until the background app and Spotlight panel foundation is working.
