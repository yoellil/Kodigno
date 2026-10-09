# Kodigno

An offline study app. Add a photo, PDF, Word document or text file; Kodigno reads the text and uses an AI model running on your own computer to make a quiz and flashcards. No account, and your notes never leave your machine.

Status: Windows desktop first. Android, iOS, audio and YouTube sources are planned (see `docs/superpowers/specs/2026-10-09-kodigno-design.md`).

## How it works
- Text comes from the file: OCR for images (bundled Tesseract), text layer for PDFs, XML for DOCX.
- A local llama.cpp server (`llama-server`, bound to 127.0.0.1) runs a small Qwen2.5 model that writes the questions.
- The model is downloaded once on first run (Basic about 470 MB, Standard about 1 GB, High about 2 GB), picked by your PC's RAM. After that it works offline.
- Study sets, quiz scores and streaks are stored locally in SQLite.

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
