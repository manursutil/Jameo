# Jameo

Jameo is a small native macOS utility for asking quick questions to a local Ollama model.

The app works like a lightweight Spotlight-style assistant: it lives in the menu bar, opens with a global keyboard shortcut, and streams concise one-shot answers from Ollama. It can also include the current screen with a question when the selected Ollama model supports vision.

## Features

- Native SwiftUI macOS app.
- Spotlight-style floating prompt panel.
- Global shortcut: `Cmd + Shift + Space`.
- Ask one-shot questions and receive streamed answers.
- Optional explicit current-screen context for the next submitted question.
- Screen-only questions when screen context is enabled and the prompt is empty.
- Vision-model capability checks before enabling or sending screen context.
- In-memory screen capture only; captured screen images are not written to disk or preserved.
- Concise assistant prompt that replies in the user's language.
- Localized English and Spanish UI that follows the system language.
- Settings window for:
  - Local downloaded Ollama model selection.
  - Reasoning mode.
  - Preserving prompt and answer between panel opens.
- Menu bar actions for opening Jameo, opening settings, and quitting the app.

## Requirements

- macOS.
- Xcode.
- Ollama running locally.
- A pulled Ollama model. The default model is `qwen3.5:9b`.
- Ollama available at `http://127.0.0.1:11434`.
- A vision-capable Ollama model for screen-context questions.
- macOS Screen Recording permission when first using screen context.

## Getting Started

1. Install and start Ollama.
2. Pull the default model:

   ```sh
   ollama pull qwen3.5:9b
   ```

3. For screen context, pull a vision-capable model and select it in Jameo settings.
4. Open `Jameo.xcodeproj` in Xcode.
5. Build and run the app.
6. Use `Cmd + Shift + Space` to open or close the Jameo panel.

## Screen Context

Screen context is explicit and per-question. Use the display button in the prompt bar to include the current screen with the next submission. Jameo captures the display containing the panel at submit time, hides its own panel before capture, downsizes the image for model input, then restores the panel while the answer streams.

If Screen Recording permission is missing or the selected model is not vision-capable, Jameo does not silently fall back to a text-only request. The screen-context toggle stays available only when the selected model reports vision support.

## Future Features

- Configurable global keyboard shortcut.
- More privacy controls around captured context.
- Improved answer formatting.
- More UI languages.
- Packaging and distribution outside Xcode.
