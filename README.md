# Jameo

Jameo is a small native macOS utility for asking quick questions to a local Ollama model.

The app is designed to work like a lightweight Spotlight-style assistant: it lives in the menu bar, opens with a global keyboard shortcut, and streams a concise answer from Ollama.

## Features

- Native SwiftUI macOS app.
- Spotlight-style floating prompt panel.
- Global shortcut: `Cmd + Shift + Space`.
- Ask one-shot questions and receive streamed answers.
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

## Getting Started

1. Install and start Ollama.
2. Pull the default model:

   ```sh
   ollama pull qwen3.5:9b
   ```

3. Open `Jameo.xcodeproj` in Xcode.
4. Build and run the app.
5. Use `Cmd + Shift + Space` to open or close the Jameo panel.

## Future Features

- Configurable global keyboard shortcut.
- Optional screen or app context awareness.
- More privacy controls around captured context.
- Improved answer formatting.
- More UI languages.
- Packaging and distribution outside Xcode.
