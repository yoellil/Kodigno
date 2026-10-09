#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "kodigno/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HWND hwnd = GetHandle();
    const std::string& method = call.method_name();
    if (method == "minimize") {
      result->Success();
      ShowWindow(hwnd, SW_MINIMIZE);
    } else if (method == "close") {
      result->Success();
      // The normal close path, so the app can stop its model server first.
      PostMessage(hwnd, WM_CLOSE, 0, 0);
    } else if (method == "toggleFullscreen") {
      result->Success(flutter::EncodableValue(ToggleFullscreen()));
    } else if (method == "isFullscreen") {
      result->Success(flutter::EncodableValue(fullscreen_));
    } else if (method == "startDrag") {
      // Hand the press to Windows as if it were on the caption; Windows then
      // runs its own move loop. A full-screen window stays put.
      result->Success();
      if (fullscreen_) return;
      ReleaseCapture();
      SendMessage(hwnd, WM_NCLBUTTONDOWN, HTCAPTION, 0);
    } else {
      result->NotImplemented();
    }
  });

  // Fixed size: no resizable frame and no maximize (so no Snap or
  // double-click maximize either). Minimize stays.
  LONG_PTR style = GetWindowLongPtr(GetHandle(), GWL_STYLE);
  style &= ~(WS_THICKFRAME | WS_MAXIMIZEBOX);
  SetWindowLongPtr(GetHandle(), GWL_STYLE, style);

  // Recompute the frame now that the non-client area is gone (see below).
  SetWindowPos(GetHandle(), nullptr, 0, 0, 0, 0,
               SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

bool FlutterWindow::ToggleFullscreen() {
  HWND hwnd = GetHandle();
  if (!fullscreen_) {
    GetWindowRect(hwnd, &restore_rect_);
    MONITORINFO info{sizeof(MONITORINFO)};
    GetMonitorInfo(MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST), &info);
    const RECT& m = info.rcMonitor;  // the whole screen, taskbar included
    SetWindowPos(hwnd, HWND_TOP, m.left, m.top, m.right - m.left, m.bottom - m.top,
                 SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    fullscreen_ = true;
  } else {
    const RECT& r = restore_rect_;
    SetWindowPos(hwnd, nullptr, r.left, r.top, r.right - r.left, r.bottom - r.top,
                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED);
    fullscreen_ = false;
  }
  return fullscreen_;
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Borderless: the client area takes the whole window, so there is no title
  // bar or border. Maximized windows hang past the screen by the frame size,
  // so pull them back in.
  if (message == WM_NCCALCSIZE && wparam == TRUE) {
    if (IsZoomed(hwnd)) {
      auto* params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
      const UINT dpi = GetDpiForWindow(hwnd);
      const int frame_x = GetSystemMetricsForDpi(SM_CXFRAME, dpi) +
                          GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
      const int frame_y = GetSystemMetricsForDpi(SM_CYFRAME, dpi) +
                          GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
      params->rgrc[0].left += frame_x;
      params->rgrc[0].right -= frame_x;
      params->rgrc[0].top += frame_y;
      params->rgrc[0].bottom -= frame_y;
    }
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
