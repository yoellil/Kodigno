# Device test log

## Task 9 smoke test (dev PC, CPU only)
- llama.cpp b11515 `llama-server` (win-cpu-x64) + `qwen2.5-0.5b-instruct-q4_k_m` (SHA-256 matches `assets/model_tiers.json`).
- First prompt (with `"..."` placeholders in the example): the 0.5B model copied the placeholders and looped until the token limit -> unparseable. Fixed by using a concrete example and "exactly 4 choices".
- After the fix: 6 of 6 runs produced parseable JSON, about 4 s each for 600 max tokens (after the first run warmed the file cache).
- OCR smoke: Tesseract 5 on a generated PNG returned "Mitochondria make ATP" exactly.
- Bundle size note: pruned Tesseract is about 174 MB (mostly DLLs and `eng.traineddata`).
