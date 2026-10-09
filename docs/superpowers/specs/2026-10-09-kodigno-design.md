# Kodigno — Design Spec

Date: 2026-10-09 (revised same day: desktop-first, new UI direction, source roadmap)

## 1. Purpose

Kodigno is an offline study app. The user adds study material (a photo or scan of notes, a PDF, a Word document, plain text); Kodigno extracts the text and uses an AI model running on the device to generate quiz questions and flashcards. The user takes the quiz, sees a score, reviews flashcards, and keeps everything in a local library.

Core promises:
- Works with no internet after a one-time model download.
- Notes are never sent to an online AI service. No account, no backend.
- One Flutter codebase targeting desktop (Windows first), Android and iOS.

## 2. Scope and roadmap

The full product vision includes more source types than the first build can deliver safely. Each phase below is its own spec -> plan -> build cycle.

| Phase | Content | Status |
|---|---|---|
| 1 | Windows desktop app. Sources: image (OCR), PDF (text), DOCX, TXT. Outputs: quiz, flashcards, notes view. Library with stats. Full UI system (responsive shell, built so mobile reuses it). | **This spec / plan** |
| 2 | Android + iOS: camera capture, mobile OCR (ML Kit), mobile LLM runtime, mobile device tiers. | Later spec |
| 3 | Audio sources: recordings and audio files transcribed by a local speech model (whisper.cpp). Needs a second model download. | Later spec |
| 4 | YouTube source: fetch a video's transcript. This one source needs internet by nature; it must be opt-in and clearly marked, and everything after the fetch stays on-device. | Later spec |
| 5 | Podcast output: LLM writes a script, a local text-to-speech model reads it. Needs a TTS model. | Later spec |
| 6 | Spaced repetition ("next review"), guides. | Later spec |

Phase 1 UI shows Audio ("Record"), YouTube and Podcast as disabled "Coming soon" entries so the layout matches the reference from day one.

### Out of scope for Phase 1
Camera capture, mobile builds, scanned-PDF OCR (a PDF with no text layer reports "no text found"), clipboard image paste, audio, YouTube, podcast, spaced repetition, cloud sync, accounts.

## 3. Architecture

Flutter app, three layers:

- **UI**: responsive shell, library, add-source, generating, set detail, notes, quiz, results, flashcards, settings, first-run model setup.
- **Services**:
  - `SourceReader` — turns a file path into text. Dispatches by extension: images -> `OcrService`; `.pdf` -> `PdfTextExtractor`; `.docx` -> unzip + read `word/document.xml`; `.txt`/`.md` -> read file.
  - `OcrService` — Phase 1 desktop: `TesseractCliOcr`, which runs a bundled `tesseract.exe` with the English model. Mobile (Phase 2): ML Kit.
  - `AiEngine` — `generate(notes, {onProgress})`: chunk -> prompt -> `LlmRuntime` -> parse/validate -> retry -> dedupe.
  - `LlmRuntime` — Phase 1 desktop: `LlamaServerRuntime`, which launches a bundled `llama-server.exe` (llama.cpp) bound to 127.0.0.1 on a free port and talks to it over its local HTTP chat API. Mobile (Phase 2): a plugin or native adapter behind the same interface.
  - `ModelManager` — device detection, tier choice, download, resume, checksum, install marker.
- **Storage**: SQLite via `drift`.

### Pipeline
File -> `SourceReader` -> text (user may edit) -> `AiEngine` -> validated JSON -> saved as a study set (with source text kept for the Notes view).

### Offline behavior
After the model is downloaded, the app makes no external network calls. The only network traffic is localhost between the app and its own `llama-server` process. Until the model is installed, AI features are locked.

### Bundled third-party binaries (Windows)
`tesseract.exe` + DLLs + `eng.traineddata` (Apache-2.0) and `llama-server.exe` + DLLs (MIT) are shipped in the app bundle under `third_party/`, copied next to the executable at build time. License files travel with them.

## 4. Device tiers and model selection

### Detection
On first run, before downloading, read total RAM (Windows: `device_info_plus` `systemMemoryInMegabytes`) and free disk space on the drive holding the models folder. RAM is the primary signal.

### Tiers (starting values; tune on real devices)

| Tier | RAM | Model (quantized GGUF) | Download |
|---|---|---|---|
| Low | < 3.5 GB | Qwen2.5 0.5B | ~400 MB |
| Standard | 3.5–7 GB | Qwen2.5 1.5B | ~1 GB |
| High | >= 7 GB | Qwen2.5 3B | ~2 GB |

Thresholds sit below the marketing numbers because operating systems report slightly less RAM than the box says. Desktop inference is CPU-only in Phase 1, so speed on the High tier must be measured, not assumed.

### Behavior
- The app recommends a tier. Settings lets the user override it.
- Warn if the user picks a tier above the recommendation, or if free storage is under 125% of the model size.
- Low tier compensates for weaker output with shorter chunks and fewer items per chunk, and is labeled "Basic quality".
- Runtime fallback: if the model server fails to start or dies (out of memory), drop one tier and offer to download the smaller model.
- The tier table is a bundled JSON config (model name, URL, size, checksum, RAM threshold, chunk size, items per chunk).

### Download
Once, with progress, resume, and SHA-256 verification. A model counts as installed only after the checksum passes (an `.ok` marker is written last).

## 5. UI design system

Reference: the user supplied a screenshot of a modern study app (pastel cards, heavy black display type, yellow pill buttons, large stat numbers). Kodigno copies the look and feel, not the other app's branding, copy, mascot, or artwork.

### Tokens (approximate, from the reference; tune by eye)
- Canvas is white (the lavender in the reference screenshots was only their backdrop); pastels are for cards and accents. Lavender card `#A9A7F2`; yellow `#F7C61C`; pink `#F2A7A5`; mint `#A6E3C3`; blue `#2D4DE8`; ink `#0F0F0F`; tile grey `#F3F3F3`; white panels.
- Type: Bricolage Grotesque (open font, bundled as an asset because the app is offline). Display text at weight 800 with tight tracking; body at 500.
- Shape: 24–32 px rounded panels, pill buttons. Primary action = yellow pill with dark text; secondary = dark pill.
- Source-type tag on library cards (IMAGE / PDF / DOCX / TEXT); card color cycles through yellow, lavender, pink, mint.

### Motion
- Shared durations and curves in `lib/ui/motion.dart`; screens fade/rise in with a short stagger, stat numbers count up, progress bars animate, stickers (`KSticker`) decorate headers, confetti on a good quiz score.
- Reduce motion: when the OS asks for it, every animation collapses to an instant change.
- No infinite animations (keeps widget tests deterministic and saves battery).

### Layout
- Desktop (>= 800 px wide): white sidebar (logo, Library, Create, Settings) beside the content area on the white canvas.
- Narrow (< 800 px): same screens with a bottom navigation bar. Built now so Phase 2 mobile reuses it.

### Screens (map to the reference)
- **Library**: "My library" title, search, grid of set cards (tag, title, progress bar = last quiz score), "Add source" yellow pill, big stat "Answered this week N", chips "Sets N" and "Streak N days".
- **Add source**: dashed drop zone ("Drop files here"), source tiles (Image, PDF, DOCX, Text active; Record, YouTube disabled), extracted-text review box, "Generate study materials" yellow pill.
- **Generating**: file chip, big percentage, progress bar, step checklist.
- **Set detail**: tiles Notes / Flashcards (N cards) / Quiz (N questions) / Podcast (disabled), "Start studying" yellow pill.
- **Quiz**: progress bar, "4 / 12", lavender question card, lettered options A–D, selected option turns yellow with a check, Next button.
- **Results**: "quiz complete", huge percentage, "10 of 12 correct", two stat circles (correct / to review), list of missed questions with right answers.
- **Flashcards**: large lavender card that flips (3D turn) to a yellow answer; swipe or arrow keys move through the deck; waiting cards rise a slot as the top card leaves; Space or tap flips.
- **Settings / Setup**: model tier, download, progress.

## 6. Data model (SQLite)

- `study_set`: id, title, source_type, source_text, source_paths (JSON), created_at.
- `question`: id, study_set_id, type, prompt, choices (JSON), answer_index, explanation.
- `flashcard`: id, study_set_id, front, back.
- `attempt`: id, study_set_id, score, total, duration_seconds, results (JSON), taken_at.

Derived: last score % per set; "answered this week" = sum of `total` of attempts in the last 7 days; streak = consecutive days (ending today or yesterday) with at least one attempt.

## 7. Error handling

- No text found (blank image, scanned PDF, empty DOCX): show a message, let the user type or paste text, block generation on empty text.
- Unsupported file type: message listing supported types.
- Malformed AI JSON: validate, retry up to 2 more times, then "couldn't generate, try again".
- Interrupted download: resume; the partial file is kept.
- Low storage: warn before downloading.
- Missing/corrupt model or dead `llama-server`: tier fallback offer.
- Very long source: at most 6 chunks are processed so generation time is bounded.

## 8. Testing

- Unit tests: tier picker, JSON parser, chunker/prompt builder, AI engine with a fake runtime, streak/stats, DOCX text extraction, source dispatcher, Tesseract argument handling, downloader (local test HTTP server), `LlamaServerRuntime` against a fake local server.
- Widget tests: add-source empty-text case, quiz flow and results.
- Manual on the dev PC: full flow with each tier's model, plus airplane-mode run after install.

## 9. Prerequisites and risks

- Building Windows apps needs Visual Studio with the "Desktop development with C++" workload and Windows Developer Mode (plugin symlinks). Android SDK is not needed until Phase 2.
- Bundled binaries add roughly 50–100 MB to the app; their licenses must be shipped.
- CPU-only inference may be slow on weak laptops; the tier system and chunk cap are the mitigations, and real timings go in the device test log.
- Qwen 0.5B output quality may be poor; retry and validation reduce, not remove, bad output.
- PDF text extraction uses pdfrx; unmappable symbols come out as U+FFFD and are stripped.
- A bundled `llama-server` that outlives the app (crash, killed process) is stopped on the next start via a pid file.
- The YouTube source (Phase 4) is the one place the offline promise has an exception; it needs its own explicit opt-in design.
