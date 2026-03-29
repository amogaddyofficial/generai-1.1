# Build Setup EXE

Questo setup installa il progetto completo con queste regole:

- include tutti i file e cartelle del progetto
- esclude completamente `sito web`
- non include i file dentro `conversazioni`
- crea comunque la cartella `conversazioni` vuota

## Come generare il setup

1. Installa Inno Setup 6: <https://jrsoftware.org/isinfo.php>
2. Esegui `installer/build_setup.bat`
3. Trovi l'exe in `installer/output/GenerAI-Setup-1.0.exe`
