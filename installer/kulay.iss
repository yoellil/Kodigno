; Build: flutter build windows --release, then: iscc installer\kulay.iss  -> installer\Output\Kulay-Setup.exe
; Needs Inno Setup 6: winget install JRSoftware.InnoSetup
[Setup]
AppName=Kulay
AppVersion=1.0.0
AppPublisher=Kulay
DefaultDirName={autopf}\Kulay
DefaultGroupName=Kulay
OutputBaseFilename=Kulay-Setup
OutputDir=Output
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\Kulay.exe
SetupIconFile=..\windows\runner\resources\app_icon.ico

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

; Model preinstalled (file + .ok marker) so first run needs no download. Copy both from
; %APPDATA%\Kulay\Kulay\models into installer\payload after a verified in-app download.
Source: "payload\qwen2.5-1.5b-instruct-q4_k_m.gguf"; DestDir: "{userappdata}\Kulay\Kulay\models"; Flags: nocompression onlyifdoesntexist uninsneveruninstall
Source: "payload\qwen2.5-1.5b-instruct-q4_k_m.gguf.ok"; DestDir: "{userappdata}\Kulay\Kulay\models"; Flags: onlyifdoesntexist uninsneveruninstall

[Icons]
Name: "{group}\Kulay"; Filename: "{app}\Kulay.exe"
Name: "{autodesktop}\Kulay"; Filename: "{app}\Kulay.exe"

[Run]
Filename: "{app}\Kulay.exe"; Description: "Launch Kulay"; Flags: nowait postinstall skipifsilent
