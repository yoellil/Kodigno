# third_party binaries (not committed)

Copied next to the app executable at build time (see windows/CMakeLists.txt).

- `tesseract/` - from the UB Mannheim Tesseract Windows build (Apache-2.0), installed with
  `winget install UB-Mannheim.TesseractOCR`, then copied from `C:\Program Files\Tesseract-OCR`.
  Pruned to `tesseract.exe`, its DLLs and `tessdata/{eng,osd}.traineddata` plus configs.
  Keep license files if present.
- `llama/` - `llama-server.exe` + DLLs from llama.cpp release `b11515`, asset
  `llama-b11515-bin-win-cpu-x64.zip` (MIT):
  https://github.com/ggml-org/llama.cpp/releases/download/b11515/llama-b11515-bin-win-cpu-x64.zip
- `piper/` - Piper neural voice for Kulay's read-aloud (MIT): `piper_windows_amd64.zip` from
  https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_windows_amd64.zip (contents of its `piper/` folder),
  plus the voice `en_US-ljspeech-medium.onnx` and `.onnx.json` from
  https://huggingface.co/rhasspy/piper-voices/tree/main/en/en_US/ljspeech/medium (trained on the public-domain LJ Speech dataset, so it is safe to ship).
  `piper.exe` bundles `espeak-ng.dll` (GPL-3.0, https://github.com/espeak-ng/espeak-ng); keep that credit if you redistribute.

Layout: `third_party/tesseract/tesseract.exe`, `third_party/tesseract/tessdata/eng.traineddata`, `third_party/llama/llama-server.exe`, `third_party/piper/piper.exe`. `windows/CMakeLists.txt` copies the whole `third_party/` folder next to `Kulay.exe`.
