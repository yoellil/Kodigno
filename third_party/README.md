# third_party binaries (not committed)

Copied next to the app executable at build time (see windows/CMakeLists.txt).

- `tesseract/` - from the UB Mannheim Tesseract Windows build (Apache-2.0), installed with
  `winget install UB-Mannheim.TesseractOCR`, then copied from `C:\Program Files\Tesseract-OCR`.
  Pruned to `tesseract.exe`, its DLLs and `tessdata/{eng,osd}.traineddata` plus configs.
  Keep license files if present.
- `llama/` - `llama-server.exe` + DLLs from llama.cpp release `b11515`, asset
  `llama-b11515-bin-win-cpu-x64.zip` (MIT):
  https://github.com/ggml-org/llama.cpp/releases/download/b11515/llama-b11515-bin-win-cpu-x64.zip

Layout: `third_party/tesseract/tesseract.exe`, `third_party/tesseract/tessdata/eng.traineddata`, `third_party/llama/llama-server.exe`. `windows/CMakeLists.txt` copies both folders next to `kodigno.exe`.
