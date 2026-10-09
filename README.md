# Kodigno

An offline study app. Add a photo, PDF, Word document or text file; Kodigno reads the text and uses an AI model running on your own computer to make a quiz and flashcards. No account, and your notes never leave your machine.

Status: Windows desktop first. Android, iOS, audio and YouTube sources are planned (see `docs/superpowers/specs/2026-10-09-kodigno-design.md`).

## How it works
- Text comes from the file: OCR for images (bundled Tesseract), text layer for PDFs, XML for DOCX.
- A local llama.cpp server (`llama-server`, bound to 127.0.0.1) runs a small Qwen2.5 model that writes the questions.
- The model is downloaded once on first run (Basic about 470 MB, Standard about 1 GB, High about 2 GB), picked by your PC's RAM. After that it works offline.
- Study sets, quiz scores and streaks are stored locally in SQLite.

## Kulay reading lab
Kulay (open it from the Kulay button in the nav) is a reading lab for Grades 1 to 12. The same local model writes an English story at the reader's color level (8 colors), asks questions about it, and shows the sentence that holds the answer when a reader gets one wrong. Scores of 80% or more on 3 stories in a row move the reader up a color. It works for one reader ("Just me") or a class taking turns on one computer, with a teacher view behind a PIN.
- Every story and question passes rule-based language checks (`lib/reading/nlp.dart`) and the model must answer its own questions before a reader sees them.
- 23 hand-reviewed starter stories ship in `assets/kulay/` for slow PCs and for when the model cannot run.
- Read-aloud uses the speech engine built into Windows. Nothing goes online.
- Design: `docs/superpowers/specs/2026-10-09-kulay-reading-design.md`.

## Build (Windows)
Needs Flutter, Visual Studio with the C++ desktop workload, and Windows Developer Mode (plugins need symlinks).

1. Put the two bundled engines in `third_party/` (not committed; see `third_party/README.md`).
2. Run:

```
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run -d windows
```
