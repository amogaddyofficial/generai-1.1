@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul 2>&1

REM ══════════════════════════════════════════════
REM   GenerAI Studio v1.1 - Launcher Universale
REM   Funziona su qualsiasi PC Windows
REM ══════════════════════════════════════════════

REM Imposta la cartella del progetto come quella dove si trova questo .bat
set "PROJECT_DIR=%~dp0"
cd /d "%PROJECT_DIR%"

echo.
echo ══════════════════════════════════════════════
echo   GENERAI STUDIO v1.1 - Launcher
echo   Cartella: %PROJECT_DIR%
echo ══════════════════════════════════════════════
echo.

REM ──────────────────────────────────────────────
REM   1. Verifica che Python sia installato
REM ──────────────────────────────────────────────
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRORE] Python non trovato!
    echo.
    echo Scarica Python da: https://www.python.org/downloads/
    echo Assicurati di selezionare "Add Python to PATH" durante l'installazione.
    echo.
    pause
    exit /b 1
)

echo [OK] Python trovato.

REM ──────────────────────────────────────────────
REM   2. Crea virtual environment se non esiste
REM ──────────────────────────────────────────────
if not exist "%PROJECT_DIR%venv\Scripts\python.exe" (
    echo.
    echo [SETUP] Creazione ambiente virtuale...
    python -m venv "%PROJECT_DIR%venv"
    if %errorlevel% neq 0 (
        echo [ERRORE] Creazione venv fallita.
        pause
        exit /b 1
    )
    echo [OK] Ambiente virtuale creato.
)

REM Attiva il venv
call "%PROJECT_DIR%venv\Scripts\activate.bat"

REM ──────────────────────────────────────────────
REM   3. Installa dipendenze se mancanti
REM ──────────────────────────────────────────────
pip show llama-cpp-python >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [SETUP] Installazione dipendenze...
    pip install llama-cpp-python
    if %errorlevel% neq 0 (
        echo.
        echo [AVVISO] Installazione llama-cpp-python fallita.
        echo   Se usi Python 3.13+, prova Python 3.10-3.12.
        echo   Il server partira' senza motore AI.
        echo.
    )
)

REM ──────────────────────────────────────────────
REM   4. Crea cartella conversazioni se mancante
REM ──────────────────────────────────────────────
if not exist "%PROJECT_DIR%conversazioni" (
    mkdir "%PROJECT_DIR%conversazioni"
    echo [OK] Cartella conversazioni creata.
)

REM ──────────────────────────────────────────────
REM   5. Scegli porta e avvia
REM ──────────────────────────────────────────────
echo.
set /p PORT_NUM="Scegli la porta per il server [8000]: "
if "%PORT_NUM%"=="" set PORT_NUM=8000

echo.
echo [INFO] Avvio GenerAI Studio sulla porta %PORT_NUM%...
echo [INFO] Dashboard: http://localhost:%PORT_NUM%
echo.

python "%PROJECT_DIR%server.py" %PORT_NUM%

if %errorlevel% neq 0 (
    echo.
    echo [ERRORE] Il server si e' interrotto.
    pause
) else (
    echo.
    echo [INFO] Server terminato.
    pause
)

endlocal
