# Jameo

Jameo is a small native macOS utility for asking quick questions to a local
Ollama model.

It behaves like a lightweight Spotlight-style assistant: it lives in the menu
bar, opens with a global keyboard shortcut, and streams concise one-shot answers
from Ollama. When the selected Ollama model supports vision, Jameo can also
include the current screen with a question.

## What It Does

- Opens a floating prompt panel from anywhere on macOS.
- Sends one-shot questions to a local Ollama model and streams the answer back.
- Uses a concise system prompt that answers in the user's language by default.
- Optionally includes the current screen with the next submitted question.
- Supports screen-only questions when screen context is enabled and the prompt is empty.
- Checks whether the selected model supports vision before enabling screen context.
- Keeps captured screen images in memory only; they are not written to disk,
  logs, or history.
- Provides English and Spanish UI strings based on the system language.
- Lets you choose a local Ollama model, toggle reasoning mode, and decide whether
  the panel should preserve the last prompt and answer between opens.

## Requirements

- macOS with Xcode installed.
- Ollama running locally.
- At least one downloaded Ollama model.
- Ollama available at `http://127.0.0.1:11434`.
- A vision-capable Ollama model if you want screen-context questions.
- macOS Screen Recording permission when first using screen context.

The default model is:

```sh
qwen3.5:9b
```

You can select another downloaded model in Jameo's settings.

## Getting Started

1. Install Ollama from [ollama.com](https://ollama.com/).
2. Start Ollama.
3. Pull the default model:

   ```sh
   ollama pull qwen3.5:9b
   ```

4. Optional: pull a vision-capable model for screen context.
5. Open `Jameo.xcodeproj` in Xcode.
6. Build and run the `Jameo` scheme.
7. Press `Cmd + Shift + Space` to open or close the Jameo panel.

Jameo runs as a menu-bar accessory app, so it does not appear as a normal Dock
window.

## Using Jameo

Open the panel with `Cmd + Shift + Space`, type a question, and press Return or
the submit button. Jameo sends the question to the selected Ollama model and
streams the response into the panel.

The panel is intentionally one-shot. It does not maintain a multi-message chat
history, and preserved prompt or answer text is display state only.

The menu bar item includes:

- `Open Jameo`
- `Settings...`
- `Quit Jameo`

## Screen Context

Screen context is explicit and per-question.

Use the display button in the prompt bar to include the current screen with the
next submission. Jameo captures the display containing the panel at submit time,
hides its own panel before capture, downsizes the image for model input, then
restores the panel while the answer streams.

If the prompt is empty and screen context is enabled, Jameo sends a neutral
screen-only question asking the model to help explain what is on the screen.

Important behavior:

- Screen context is only available when the selected model reports vision support.
- Jameo re-checks vision support before sending a screen-context request.
- If Screen Recording permission is missing, Jameo stops the submission and asks
  macOS for permission instead of silently sending a text-only request.
- Captured screen images are kept only in memory for the request.
- Captured images are not stored, logged, or preserved between panel opens.
- After a successful screen-context submission, the screen-context toggle resets.

## Settings

Open settings from the menu bar item.

Available settings:

- `Model`: choose from locally downloaded Ollama models.
- `Enable reasoning`: passes the reasoning flag through to Ollama for the
  selected model.
- `Preserve prompt and answer when opening`: keeps the last visible prompt and
  response when reopening the panel.

If you pull a new Ollama model while Jameo is running, use `Refresh` in settings
to reload the local model list.

## Project Layout

```text
Jameo/
  AppDelegate.swift                 Menu bar app, settings window, global hotkey.
  SpotlightPanelController.swift    Floating Spotlight-style panel behavior.
  ContentView.swift                 Prompt panel UI.
  PromptTextField.swift             Focusable prompt input.
  JameoViewModel.swift              Panel state and request orchestration.
  OllamaService.swift               Local Ollama client integration.
  ScreenContextCaptureService.swift ScreenCaptureKit-based display capture.
  SettingsView.swift                Model, reasoning, and panel settings.
  Localizable.xcstrings             English and Spanish UI strings.

docs/adr/
  0001-explicit-screen-context.md   Screen-context product decision.

CONTEXT.md                          Product language and design direction.
```

## Development Notes

- Keep Jameo a small native macOS utility rather than a conventional chat app.
- Prefer built-in AppKit, SwiftUI, and macOS APIs before adding dependencies.
- Treat screen content as privacy-sensitive. Screen context should stay explicit,
  per-question, and in-memory.
- Do not add OCR or silent text-only fallback for screen-context requests unless
  the product decision changes.
- Keep the assistant interaction one-shot unless a future design explicitly adds
  conversation history.

## Troubleshooting

### No Models Appear In Settings

Make sure Ollama is running and has at least one downloaded model:

```sh
ollama list
```

Pull a model if the list is empty, then refresh the model list in Jameo settings.

### Requests Fail Immediately

Check that Ollama is reachable at the local default endpoint:

```sh
curl http://127.0.0.1:11434/api/tags
```

If this fails, start or restart Ollama.

### Screen Context Is Disabled

The selected model probably does not report vision support. Select a
vision-capable local model in settings, or pull one with Ollama and refresh the
model list.

### Screen Capture Fails

Grant Screen Recording permission to Jameo in macOS System Settings, then retry
the question. Depending on macOS behavior, you may need to restart the app after
granting permission.

## Roadmap

- Configurable global keyboard shortcut.
- Additional privacy controls around captured context.
- Improved answer formatting.
- More UI languages.
- Packaging and distribution outside Xcode.
