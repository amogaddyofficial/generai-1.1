#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#   GenerAI Studio v1.1 - Launcher (Linux / macOS)
# ══════════════════════════════════════════════════════════════

set -e
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  GENERAI STUDIO v1.1 - Launcher"
echo "  Cartella: $PROJECT_DIR"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────────────────────
#   1. Verifica Python 3
# ──────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "[ERRORE] Python 3 non trovato!"
    echo "  Ubuntu/Debian: sudo apt install python3 python3-venv"
    echo "  macOS:         brew install python3"
    exit 1
fi

# ──────────────────────────────────────────────────────────────
#   2. Crea venv se non esiste
# ──────────────────────────────────────────────────────────────
if [[ ! -f "$PROJECT_DIR/venv/bin/python" ]]; then
    echo "[SETUP] Creazione ambiente virtuale..."
    python3 -m venv "$PROJECT_DIR/venv"
    echo "[OK] Ambiente virtuale creato."
fi

# Attiva venv
source "$PROJECT_DIR/venv/bin/activate"

# ──────────────────────────────────────────────────────────────
#   3. Installa dipendenze se mancanti
# ──────────────────────────────────────────────────────────────
if ! python -c "import llama_cpp" &>/dev/null 2>&1; then
    echo "[SETUP] Installazione dipendenze..."
    pip install -r "$PROJECT_DIR/requirements.txt" || {
        echo "[AVVISO] Alcune dipendenze non installate. Il server partirà senza motore AI."
    }
fi

# ──────────────────────────────────────────────────────────────
#   4. Crea cartella conversazioni se mancante
# ──────────────────────────────────────────────────────────────
mkdir -p "$PROJECT_DIR/conversazioni"

# ──────────────────────────────────────────────────────────────
#   5. Scegli porta e avvia
# ──────────────────────────────────────────────────────────────
echo ""
read -rp "Porta del server [8000]: " PORT_NUM
PORT_NUM="${PORT_NUM:-8000}"

echo ""
echo "[INFO] Avvio GenerAI Studio sulla porta $PORT_NUM..."
echo "[INFO] Dashboard: http://localhost:$PORT_NUM"
echo ""

python "$PROJECT_DIR/server.py" "$PORT_NUM"
