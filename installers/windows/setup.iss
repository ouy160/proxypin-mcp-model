; ProxyPin MCP — Inno Setup Script
; Run via CI: iscc /DAppVersion=x.y.z setup.iss
; (paths are relative to this file's location)

#define AppName      "ProxyPin MCP"
#define AppExeName   "ProxyPin.exe"
#define AppPublisher "ProxyPin"
#define AppURL       "https://github.com/SuxyEE/proxypin-mcp"
#define AppId        "502CBCA5-A7F1-4F8F-894D-9820BAC2E36F"

[Setup]
AppId={{{#AppId}}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf64}\{#AppName}
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=proxypin-mcp-windows-{#AppVersion}-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
CloseApplications=force
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}";  Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
