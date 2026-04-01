#define MyAppName "GenerAI"
#define MyAppVersion "1.1"
#define MyAppPublisher "GenerAI Project"
#define MyAppExeName "start.bat"
#define MyAppURL "https://github.com/amogaddyofficial/generai-1.1"
#define GGUFName "Qwen3.5-9B-Q4_K_M.gguf"
#define GGUFUrl "https://github.com/amogaddyofficial/generai-1.1/releases/download/v1.1/Qwen3.5-9B-Q4_K_M.gguf"

[Setup]
AppId={{8CF62E92-5D8D-4FD6-8CCF-AF8D8A03A17B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
Compression=lzma
SolidCompression=yes
WizardStyle=modern
OutputDir=output
OutputBaseFilename=GenerAI-Setup-1.1
MinVersion=6.1
; Richiede connessione internet per scaricare il modello GGUF

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Crea un collegamento sul Desktop"; GroupDescription: "Icone aggiuntive:"; Flags: unchecked
Name: "downloadmodel"; Description: "Scarica il modello AI (~1.3 GB) — richiede internet"; GroupDescription: "Componenti opzionali:"; Flags: checked

[Files]
; File del progetto (escludi: venv locale, conversazioni, installer, GGUF locale)
Source: "..\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion; \
    Excludes: "sito web\*,conversazioni\*,installer\*,venv\*,*.gguf,__pycache__\*,*.pyc,.git\*"

[Dirs]
; Crea la cartella conversazioni vuota
Name: "{app}\conversazioni"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; Scarica il modello GGUF se l'utente ha selezionato l'opzione
Filename: "powershell.exe"; \
    Parameters: "-NoProfile -NonInteractive -Command ""$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '{#GGUFUrl}' -OutFile '{app}\{#GGUFName}' -UseBasicParsing"""; \
    WorkingDir: "{app}"; \
    StatusMsg: "Scaricamento modello AI (~1.3 GB)... attendere..."; \
    Tasks: downloadmodel; \
    Flags: runhidden waituntilterminated

; Avvia GenerAI dopo l'installazione (opzionale)
Filename: "{app}\{#MyAppExeName}"; \
    Description: "Avvia {#MyAppName} ora"; \
    Flags: nowait postinstall skipifsilent

[Code]
// Verifica che Python sia installato prima di procedere
function InitializeSetup(): Boolean;
var
  PythonPath: String;
  ResultCode: Integer;
begin
  Result := True;
  // Controlla se python è nel PATH
  if not Exec('python', '--version', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) or (ResultCode <> 0) then
  begin
    if MsgBox(
      'Python non è installato o non è nel PATH.' + #13#10 +
      'GenerAI richiede Python 3.10-3.12.' + #13#10 + #13#10 +
      'Vuoi aprire la pagina di download di Python?',
      mbConfirmation, MB_YESNO) = IDYES then
    begin
      ShellExec('open', 'https://www.python.org/downloads/', '', '', SW_SHOW, ewNoWait, ResultCode);
    end;
    Result := False;
    Exit;
  end;
end;

// Mostra messaggio di completamento personalizzato
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssDone then
  begin
    MsgBox(
      'GenerAI Studio v1.1 installato con successo!' + #13#10 + #13#10 +
      'Cartella: ' + ExpandConstant('{app}') + #13#10 + #13#10 +
      'Avvia GenerAI con start.bat' + #13#10 +
      'GitHub: https://github.com/amogaddyofficial/generai-1.1',
      mbInformation, MB_OK);
  end;
end;
