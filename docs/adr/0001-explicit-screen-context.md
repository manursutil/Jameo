# Explicit Screen Context

Jameo will include current-screen context only when the user explicitly enables it for a submitted question. The first version captures the entire active display at submit time, sends the raw screen image to a vision-capable Ollama model, shows a lightweight screen-included confirmation, and resets the screen-context toggle after submission.

## Considered Options

- OCR-only context was rejected because screen context may include images, video frames, diagrams, charts, layout, and other non-text information.
- Semantic app context was rejected for the first version because app-specific extraction would make behavior less predictable and would add accessibility and integration complexity.
- Window-only capture was rejected for the first version because relevant context may span multiple windows, sheets, popovers, or the desktop.
- Automatic capture was rejected because screen content is privacy-sensitive and should not be sent without an explicit per-question action.
- A blocking preview was rejected because it adds friction to the Spotlight-style interaction; Jameo should instead show a lightweight confirmation that screen context was included.

## Consequences

Jameo requests or surfaces macOS Screen Recording permission only when the user first tries to submit a question with screen context enabled. If permission is missing or denied, Jameo should stop the screen-context submission and let the user grant permission and retry rather than sending a text-only question. Captured screen images are kept only in memory for the request and are not written to disk, logs, or history. Screen context is hidden or disabled when the selected model is not vision-capable; Jameo should not silently drop the captured image or fall back to OCR in the first version.
