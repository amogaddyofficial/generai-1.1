@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ══════════════════════════════════════════════════════════════
REM   GenerAI Studio v1.1 - Installer Universale (Windows)
REM   Scarica tutto da GitHub automaticamente
REM ══════════════════════════════════════════════════════════════

set "REPO_URL=https://github.com/amogaddyofficial/generai-1.1"
set "REPO_ZIP=https://github.com/amogaddyofficial/generai-1.1/archive/refs/heads/main.zip"
set "GGUF_URL=https://github.com/amogaddyofficial/generai-1.1/releases/download/v1.1/Qwen3.5-9B-Q4_K_M.gguf"
set "GGUF_NAME=Qwen3.5-9B-Q4_K_M.gguf"
set "DEFAULT_DIR=%USERPROFILE%\GenerAI"

echo.
echo ══════════════════════════════════════════════════════════════
echo   GENERAI STUDIO v1.1 - Installer
echo   Repository: %REPO_URL%
echo ══════════════════════════════════════════════════════════════
echo.

REM ──────────────────────────────────────────────────────────────
REM   1. Verifica Python
REM ──────────────────────────────────────────────────────────────
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRORE] Python non trovato!
    echo.
    echo   Scarica Python 3.10-3.12 da: https://www.python.org/downloads/
    echo   Seleziona "Add Python to PATH" durante l'installazione.
    echo.
    pause
    exit /b 1
)
echo [OK] Python trovato.

REM ──────────────────────────────────────────────────────────────
REM   2. Scegli cartella di installazione
REM ──────────────────────────────────────────────────────────────
echo.
set /p INSTALL_DIR="Cartella di installazione [%DEFAULT_DIR%]: "
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=%DEFAULT_DIR%"

if exist "%INSTALL_DIR%\server.py" (
    echo.
    echo [AVVISO] GenerAI e' gia' installato in: %INSTALL_DIR%
    set /p OVERWRITE="Sovrascrivere? [s/N]: "
    if /i not "!OVERWRITE!"=="s" (
        echo [ANNULLATO] Installazione annullata.
        pause
        exit /b 0
    )
)

echo.
echo [INFO] Installazione in: %INSTALL_DIR%
mkdir "%INSTALL_DIR%" 2>nul

REM ──────────────────────────────────────────────────────────────
REM   3. Scarica il progetto da GitHub
REM ──────────────────────────────────────────────────────────────
echo.
echo [DOWNLOAD] Scaricamento del progetto da GitHub...

REM Prova con git clone
git --version >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] Uso git clone...
    git clone "%REPO_URL%" "%INSTALL_DIR%"
    if %errorlevel% neq 0 (
        echo [AVVISO] git clone fallito, provo con download ZIP...
        goto :download_zip
    )
    goto :after_download
)

:download_zip
echo [INFO] Download ZIP via PowerShell...
powershell -Command "try { Invoke-WebRequest -Uri '%REPO_ZIP%' -OutFile '%TEMP%\generai_setup.zip' -UseBasicParsing } catch { Write-Error $_.Exception.Message; exit 1 }"
if %errorlevel% neq 0 (
    echo [ERRORE] Download fallito. Verifica la connessione internet.
    pause
    exit /b 1
)

echo [INFO] Estrazione archivio...
powershell -Command "Expand-Archive -Path '%TEMP%\generai_setup.zip' -DestinationPath '%TEMP%\generai_extract' -Force"
if %errorlevel% neq 0 (
    echo [ERRORE] Estrazione fallita.
    pause
    exit /b 1
)
xcopy "%TEMP%\generai_extract\generai-1.1-main\*" "%INSTALL_DIR%\" /E /I /Q /Y >nul
del "%TEMP%\generai_setup.zip" >nul 2>&1
rmdir /s /q "%TEMP%\generai_extract" >nul 2>&1

:after_download
echo [OK] Progetto scaricato.

REM ──────────────────────────────────────────────────────────────
REM   4. Crea cartella conversazioni
REM ──────────────────────────────────────────────────────────────
if not exist "%INSTALL_DIR%\conversazioni" (
    mkdir "%INSTALL_DIR%\conversazioni"
    echo [OK] Cartella conversazioni creata.
)

REM ──────────────────────────────────────────────────────────────
REM   5. Scarica il modello AI (GGUF, ~1.3 GB)
REM ──────────────────────────────────────────────────────────────
echo.
if exist "%INSTALL_DIR%\%GGUF_NAME%" (
    echo [OK] Modello AI gia' presente, salto il download.
) else (
    set /p DOWNLOAD_MODEL="Scaricare il modello AI (~1.3 GB)? [S/n]: "
    if /i not "!DOWNLOAD_MODEL!"=="n" (
        echo [DOWNLOAD] Scaricamento modello AI... Potrebbe richiedere diversi minuti.
        powershell -Command "try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%GGUF_URL%' -OutFile '%INSTALL_DIR%\%GGUF_NAME%' -UseBasicParsing } catch { Write-Error $_.Exception.Message; exit 1 }"
        if %errorlevel% neq 0 (
            echo [AVVISO] Download modello fallito.
            echo   Scaricalo manualmente da: %GGUF_URL%
            echo   Posizionalo in: %INSTALL_DIR%\
        ) else (
            echo [OK] Modello AI scaricato.
        )
    ) else (
        echo [SKIP] Modello saltato. Scaricalo e mettilo in: %INSTALL_DIR%\
    )
)

REM ──────────────────────────────────────────────────────────────
REM   6. Crea ambiente virtuale Python e installa dipendenze
REM ──────────────────────────────────────────────────────────────
echo.
echo [SETUP] Creazione ambiente virtuale Python...
cd /d "%INSTALL_DIR%"
python -m venv venv
if %errorlevel% neq 0 (
    echo [ERRORE] Creazione venv fallita.
    pause
    exit /b 1
)
echo [OK] Ambiente virtuale creato.

call "%INSTALL_DIR%\venv\Scripts\activate.bat"

echo [SETUP] Installazione dipendenze...
pip install --upgrade pip >nul 2>&1
pip install -r "%INSTALL_DIR%\requirements.txt"
if %errorlevel% neq 0 (
    echo [AVVISO] Alcune dipendenze potrebbero non essere installate correttamente.
)
echo [OK] Dipendenze installate.

REM ──────────────────────────────────────────────────────────────
REM   7. Crea collegamento desktop (opzionale)
REM ──────────────────────────────────────────────────────────────
echo.
set /p CREATE_SHORTCUT="Creare collegamento sul Desktop? [S/n]: "
if /i not "!CREATE_SHORTCUT!"=="n" (
    powershell -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\GenerAI.lnk'); $s.TargetPath='%INSTALL_DIR%\start.bat'; $s.WorkingDirectory='%INSTALL_DIR%'; $s.Description='GenerAI Studio v1.1'; $s.Save()"
    echo [OK] Collegamento Desktop creato.
)

REM ──────────────────────────────────────────────────────────────
REM   Installazione completata!
REM ──────────────────────────────────────────────────────────────
echo.
echo ══════════════════════════════════════════════════════════════
echo   INSTALLAZIONE COMPLETATA!
echo   Cartella: %INSTALL_DIR%
echo   Avvio: doppio click su start.bat (o collegamento Desktop)
echo ══════════════════════════════════════════════════════════════
echo.
set /p LAUNCH_NOW="Avviare GenerAI adesso? [S/n]: "
if /i not "!LAUNCH_NOW!"=="n" (
    start "" "%INSTALL_DIR%\start.bat"
)

pause
endlocal
