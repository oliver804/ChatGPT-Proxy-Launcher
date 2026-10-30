#ifndef AppVersion
  #error AppVersion must be passed by the build script
#endif
[Setup]
AppId={{14D4A6A9-568D-46E7-B2F6-22AFA190E5EC}
AppName=Local Route Launcher
AppVersion={#AppVersion}
AppPublisher=Oliver
AppPublisherURL=https://github.com/oliver804/Local-Route-Launcher
AppSupportURL=https://github.com/oliver804/Local-Route-Launcher/issues
DefaultDirName={localappdata}\Programs\Local Route Launcher
DefaultGroupName=Local Route Launcher
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.19045
OutputDir=..\..\dist\{#AppVersion}
OutputBaseFilename=Local-Route-Launcher-{#AppVersion}-windows-x64-setup
SetupIconFile=..\..\build\windows\Launcher.ico
UninstallDisplayIcon={app}\LocalRouteLauncher.exe
AppMutex=Local\LocalRouteLauncher
CloseApplications=no
RestartApplications=no
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
LicenseFile=..\..\LICENSE
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Shortcuts:"; Flags: unchecked
[Files]
Source: "..\..\build\windows\publish\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\Local Route Launcher"; Filename: "{app}\LocalRouteLauncher.exe"
Name: "{autodesktop}\Local Route Launcher"; Filename: "{app}\LocalRouteLauncher.exe"; Tasks: desktopicon
[Run]
Filename: "{app}\LocalRouteLauncher.exe"; Description: "Open Local Route Launcher"; Flags: nowait postinstall skipifsilent
; Settings intentionally remain in LocalAppData\LocalRouteLauncher after uninstall.
