@echo off
setlocal
title GenerAI Studio - STANDALONE
color 0b

echo ==========================================
echo    GENERAI STUDIO (STANDALONE) STARTUP
echo ==========================================
echo.

:: Check if Python is installed
echo [INFO] Verifica installazione Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Python non e' installato o non e' nel PATH.
    echo Per favore installa Python da https://www.python.org/
    pause
    exit /b
)

:: Check/Install llama-cpp-python
echo [INFO] Verifica dipendenze AI...
python -c "import llama_cpp" >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Motore AI ^(llama-cpp-python^) non trovato.
    echo [INFO] Installazione automatica in corso... 
    echo        ^(Questa operazione potrebbe richiedere 111-300 secondi^)
    echo.
    pip install llama-cpp-python --prefer-binary
    
    python -c "import llama_cpp" >nul 2>&1
    if %errorlevel% neq 0 (
        echo.
        echo [ERROR] Installazione fallita. 
        echo Possibili motivi:
        echo - Connessione internet assente.
        echo - Mancanza di un compilatore C++ ^(Visual Studio Build Tools^).
        echo.
        echo Prova a installare manualmente: pip install llama-cpp-python
        pause
        exit /b
    )
    echo [SUCCESS] Motore AI installato con successo.
)

echo.
set /p PORT_NUM="Scegli la porta per il server [8000]: "
if "%PORT_NUM%"=="" set PORT_NUM=8000

echo [INFO] Avvio Server Generativo sulla porta %PORT_NUM%...
echo [INFO] Caricamento modello Qwen 9B (preparazione RAM)...
echo [INFO] Dashboard: http://localhost:%PORT_NUM%
echo.

python server.py %PORT_NUM%

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Il server si e' interrotto inaspettatemente.
    echo Controlla i messaggi qui sopra per i dettagli.
    pause
) else (
    echo.
    echo [INFO] Server terminato correttamente.
    pause
)

endlocal
