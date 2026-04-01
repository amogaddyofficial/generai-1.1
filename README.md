# GenerAI Studio v1.1

AI locale con interfaccia web, basato su Qwen 3.5 9B. Funziona completamente offline dopo l'installazione.

---

## Installazione rapida

### Windows

1. Scarica [install.bat](https://github.com/amogaddyofficial/generai-1.1/releases/download/v1.1/install.bat)
2. Fai doppio click — installa tutto automaticamente:
   - Scarica il progetto da GitHub
   - Scarica il modello AI (1.3 GB)
   - Crea l'ambiente Python
   - Aggiunge collegamento sul Desktop

### Linux / macOS

```bash
curl -sL https://raw.githubusercontent.com/amogaddyofficial/generai-1.1/main/start.sh -o /tmp/install.sh
bash /tmp/install.sh
```

Oppure clona manualmente:

```bash
git clone https://github.com/amogaddyofficial/generai-1.1 ~/GenerAI
cd ~/GenerAI
bash install.sh
```

---

## Requisiti

| Requisito | Minimo | Consigliato |
|-----------|--------|-------------|
| Python | 3.10 | 3.11 / 3.12 |
| RAM | 8 GB | 16 GB |
| Spazio disco | 3 GB | 5 GB |
| OS | Windows 10 / Ubuntu 20 / macOS 12 | qualsiasi versione recente |

> Python deve essere nel PATH. Scaricalo da [python.org](https://www.python.org/downloads/) e spunta **"Add Python to PATH"** durante l'installazione.

---

## Avvio

**Windows**

```
start.bat
```

**Linux / macOS**

```bash
bash start.sh
```

Il browser si apre automaticamente su `http://localhost:8000`.

---

## Struttura del progetto

```
GenerAI/
├── server.py          # Server HTTP + motore AI (llama-cpp-python)
├── index.html         # Dashboard chat
├── editor.html        # IDE integrato
├── database.html      # Gestione database
├── start.bat          # Launcher Windows
├── start.sh           # Launcher Linux/macOS
├── requirements.txt   # Dipendenze Python
├── conversazioni/     # Storico chat (creata automaticamente)
└── Qwen3.5-9B-Q4_K_M.gguf  # Modello AI (scaricato dall'installer)
```

---

## Modello AI

- **Modello**: Qwen 3.5 9B (quantizzato Q4_K_M)
- **File**: `Qwen3.5-9B-Q4_K_M.gguf` (~1.3 GB)
- **Download diretto**: [GitHub Release v1.1](https://github.com/amogaddyofficial/generai-1.1/releases/tag/v1.1)

Il modello viene scaricato automaticamente dall'installer. Se vuoi scaricarlo manualmente, mettilo nella cartella principale del progetto.

---

## Installazione Inno Setup (Windows .exe)

Per creare un installer `.exe` professionale:

1. Installa [Inno Setup 6](https://jrsoftware.org/isinfo.php)
2. Apri `installer/GenerAI_Setup.iss`
3. Premi **Compile** (o `Ctrl+F9`)

L'installer scarica il modello GGUF da GitHub Release durante l'installazione.

---

## Repository

[github.com/amogaddyofficial/generai-1.1](https://github.com/amogaddyofficial/generai-1.1)
