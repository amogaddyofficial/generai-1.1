@echo off
setlocal

REM Percorso standard Inno Setup 6
set "ISCC=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if not exist "%ISCC%" (
  echo [ERRORE] Inno Setup non trovato in:
  echo %ISCC%
  echo.
  echo Installa Inno Setup da:
  echo https://jrsoftware.org/isinfo.php
  pause
  exit /b 1
)

echo Compilazione setup in corso...
"%ISCC%" "%~dp0GenerAI_Setup.iss"

if errorlevel 1 (
  echo [ERRORE] Compilazione setup fallita.
  pause
  exit /b 1
)

echo [OK] Setup creato con successo.
echo Output: %~dp0output\GenerAI-Setup-1.0.exe
pause
