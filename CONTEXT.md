# Jameo Context

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
