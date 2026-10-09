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
- 35 hand-reviewed starter stories ship in `assets/kulay/` for slow PCs and for when the model cannot run. New releases add new ones without touching old data.
- From Gold up, each story ends with a main-idea question, and from Red up also a thinking (inference) question. The AI must answer each one correctly twice, with the choices in opposite orders.
- Readers can time their reading (words a minute), save the words they tap to My Words and practice them, retry the questions they missed, and set a larger text size or an easy-read font ("Aa").
- Teachers can paste their own story (the AI only writes the questions), give it to one reader or a whole color, give a reader the reading check again, and save the class report as a PDF. A teacher's story is extra practice: it never moves a color.
- Read-aloud uses the speech engine built into Windows. Nothing goes online.
- Design: `docs/superpowers/specs/2026-10-09-kulay-reading-design.md`.

## Word meanings
Tapping a word in a story shows a real dictionary meaning, offline. The meanings come from [Open English WordNet 2025](https://en-word.net) (CC BY 4.0, derived from Princeton WordNet), about 69,000 words in `assets/kulay/dict/`. The AI only picks which meaning fits the sentence; it never writes one. A word the book does not have (a Filipino word or a name) is explained by the AI, and small helper words such as "about" are not tappable. Rebuild the files with `python tool/build_dictionary.py <extracted english-wordnet-2025-json.zip> assets/kulay/dict`. See `assets/kulay/dict/NOTICE.txt`.

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
