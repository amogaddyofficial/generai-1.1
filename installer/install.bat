@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

set "REPO_URL=https://github.com/amogaddyofficial/generai-1.1"
set "REPO_ZIP=https://github.com/amogaddyofficial/generai-1.1/archive/refs/heads/main.zip"
set "GGUF_URL=https://github.com/amogaddyofficial/generai-1.1/releases/download/v1.1/Qwen3.5-9B-Q4_K_M.gguf"
set "GGUF_NAME=Qwen3.5-9B-Q4_K_M.gguf"
set "INSTALL_DIR=%USERPROFILE%\GenerAI"

echo.
echo ============================================================
echo   GENERAI STUDIO v1.1 - Installer per Windows
echo   Repository: %REPO_URL%
echo ============================================================
echo.

REM --- 1. Verifica Python ---
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRORE] Python non trovato!
    echo.
    echo Scarica Python 3.10-3.12 da: https://www.python.org/downloads/
    echo Seleziona "Add Python to PATH" durante l'installazione.
    echo.
    pause
    exit /b 1
)
echo [OK] Python trovato.

REM --- 2. Scegli cartella di installazione ---
echo.
echo Cartella di installazione predefinita: %INSTALL_DIR%
set /p "USER_DIR=Premi INVIO per usare quella predefinita, o scrivi un percorso: "
if not "!USER_DIR!"=="" set "INSTALL_DIR=!USER_DIR!"

echo.
echo [INFO] Installazione in: !INSTALL_DIR!

if exist "!INSTALL_DIR!\server.py" (
    echo.
    echo [AVVISO] GenerAI e' gia' installato in: !INSTALL_DIR!
    set /p "OVERWRITE=Sovrascrivere? [s/N]: "
    if /i not "!OVERWRITE!"=="s" (
        echo [ANNULLATO]
        pause
        exit /b 0
    )
)

mkdir "!INSTALL_DIR!" 2>nul

REM --- 3. Scarica il progetto da GitHub ---
echo.
echo [DOWNLOAD] Scaricamento progetto da GitHub...

git --version >nul 2>&1
if %errorlevel% == 0 (
    echo [INFO] Uso git clone...
    git clone "!REPO_URL!" "!INSTALL_DIR!"
    if !errorlevel! neq 0 goto :download_zip
    goto :after_download
)

:download_zip
echo [INFO] Download ZIP via PowerShell...
powershell -Command "try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '!REPO_ZIP!' -OutFile '$env:TEMP\generai_setup.zip' -UseBasicParsing } catch { Write-Error $_.Exception.Message; exit 1 }"
if %errorlevel% neq 0 (
    echo [ERRORE] Download fallito. Controlla la connessione internet.
    pause
    exit /b 1
)
echo [INFO] Estrazione archivio...
powershell -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '$env:TEMP\generai_setup.zip' -DestinationPath '$env:TEMP\generai_extract' -Force"
xcopy "%TEMP%\generai_extract\generai-1.1-main\*" "!INSTALL_DIR!\" /E /I /Q /Y >nul
del "%TEMP%\generai_setup.zip" >nul 2>&1
rmdir /s /q "%TEMP%\generai_extract" >nul 2>&1

:after_download
echo [OK] Progetto scaricato.

REM --- 4. Crea cartella conversazioni ---
if not exist "!INSTALL_DIR!\conversazioni" (
    mkdir "!INSTALL_DIR!\conversazioni"
    echo [OK] Cartella conversazioni creata.
) else (
    echo [OK] Cartella conversazioni gia' presente.
)

REM --- 5. Scarica il modello AI (GGUF, ~1.3 GB) ---
echo.
if exist "!INSTALL_DIR!\!GGUF_NAME!" (
    echo [OK] Modello AI gia' presente, salto il download.
) else (
    set /p "DL_MODEL=Scaricare il modello AI (~1.3 GB)? [S/n]: "
    if /i not "!DL_MODEL!"=="n" (
        echo [DOWNLOAD] Scaricamento modello AI in corso...
        echo           Potrebbe richiedere diversi minuti.
        powershell -Command "try { $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '!GGUF_URL!' -OutFile '!INSTALL_DIR!\!GGUF_NAME!' -UseBasicParsing } catch { Write-Error $_.Exception.Message; exit 1 }"
        if !errorlevel! neq 0 (
            echo [AVVISO] Download modello fallito.
            echo          Scaricalo manualmente da: !GGUF_URL!
            echo          Posizionalo in: !INSTALL_DIR!\
        ) else (
            echo [OK] Modello AI scaricato.
        )
    ) else (
        echo [SKIP] Modello saltato. Inseriscilo manualmente in: !INSTALL_DIR!\
    )
)

REM --- 6. Ambiente virtuale Python e dipendenze ---
echo.
echo [SETUP] Creazione ambiente virtuale Python...
cd /d "!INSTALL_DIR!"
python -m venv venv
if %errorlevel% neq 0 (
    echo [ERRORE] Creazione venv fallita.
    pause
    exit /b 1
)
echo [OK] Ambiente virtuale creato.

call "!INSTALL_DIR!\venv\Scripts\activate.bat"
echo [SETUP] Installazione dipendenze...
pip install --upgrade pip -q
pip install -r "!INSTALL_DIR!\requirements.txt"
echo [OK] Dipendenze installate.

REM --- 7. Collegamento Desktop (opzionale) ---
echo.
set /p "SHORTCUT=Creare collegamento sul Desktop? [S/n]: "
if /i not "!SHORTCUT!"=="n" (
    powershell -Command "$ws=New-Object -ComObject WScript.Shell; $s=$ws.CreateShortcut([Environment]::GetFolderPath('Desktop')+'\GenerAI.lnk'); $s.TargetPath='!INSTALL_DIR!\start.bat'; $s.WorkingDirectory='!INSTALL_DIR!'; $s.Description='GenerAI Studio v1.1'; $s.Save()"
    echo [OK] Collegamento Desktop creato.
)

REM --- Fine ---
echo.
echo ============================================================
echo   INSTALLAZIONE COMPLETATA!
echo   Cartella: !INSTALL_DIR!
echo   Avvio: fai doppio click su start.bat
echo          oppure usa il collegamento Desktop
echo ============================================================
echo.
set /p "LAUNCH=Avviare GenerAI adesso? [S/n]: "
if /i not "!LAUNCH!"=="n" (
    start "" "!INSTALL_DIR!\start.bat"
)

pause
endlocal
