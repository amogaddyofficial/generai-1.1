#define MyAppName "GenerAI"
#define MyAppVersion "1.0"
#define MyAppPublisher "GenerAI Project"
#define MyAppExeName "start.bat"

[Setup]
AppId={{8CF62E92-5D8D-4FD6-8CCF-AF8D8A03A17A}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
Compression=lzma
SolidCompression=yes
WizardStyle=modern
OutputDir=output
OutputBaseFilename=GenerAI-Setup-1.0

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "Crea un collegamento sul Desktop"; GroupDescription: "Icone aggiuntive:"; Flags: unchecked

[Files]
; Include tutto il progetto, ma escludi:
; - cartella sito web completa
; - file dentro conversazioni (la cartella verra creata vuota in [Dirs])
; - cartella installer (evita di includere script e output setup)
Source: "..\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion; Excludes: "sito web\*","conversazioni\*","installer\*"

[Dirs]
; Crea la cartella conversazioni anche vuota
Name: "{app}\conversazioni"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Avvia {#MyAppName}"; Flags: nowait postinstall skipifsilent
