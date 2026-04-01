#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#   GenerAI Studio v1.1 - Installer Universale (Linux / macOS)
#   Scarica tutto da GitHub automaticamente
# ══════════════════════════════════════════════════════════════

set -e

REPO_URL="https://github.com/amogaddyofficial/generai-1.1"
REPO_ZIP="https://github.com/amogaddyofficial/generai-1.1/archive/refs/heads/main.zip"
GGUF_URL="https://github.com/amogaddyofficial/generai-1.1/releases/download/v1.1/Qwen3.5-9B-Q4_K_M.gguf"
GGUF_NAME="Qwen3.5-9B-Q4_K_M.gguf"
DEFAULT_DIR="$HOME/GenerAI"

echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  GENERAI STUDIO v1.1 - Installer (Linux / macOS)"
echo "  Repository: $REPO_URL"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ──────────────────────────────────────────────────────────────
#   1. Verifica Python 3
# ──────────────────────────────────────────────────────────────
if ! command -v python3 &>/dev/null; then
    echo "[ERRORE] Python 3 non trovato!"
    echo ""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  Installa con: brew install python3"
        echo "  Oppure scarica da: https://www.python.org/downloads/"
    else
        echo "  Ubuntu/Debian: sudo apt install python3 python3-venv python3-pip"
        echo "  Fedora/RHEL:   sudo dnf install python3"
    fi
    exit 1
fi
echo "[OK] Python 3 trovato: $(python3 --version)"

# ──────────────────────────────────────────────────────────────
#   2. Scegli cartella di installazione
# ──────────────────────────────────────────────────────────────
echo ""
read -rp "Cartella di installazione [$DEFAULT_DIR]: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_DIR}"

if [[ -f "$INSTALL_DIR/server.py" ]]; then
    echo ""
    echo "[AVVISO] GenerAI è già installato in: $INSTALL_DIR"
    read -rp "Sovrascrivere? [s/N]: " OVERWRITE
    if [[ "${OVERWRITE,,}" != "s" ]]; then
        echo "[ANNULLATO] Installazione annullata."
        exit 0
    fi
fi

echo ""
echo "[INFO] Installazione in: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# ──────────────────────────────────────────────────────────────
#   3. Scarica il progetto da GitHub
# ──────────────────────────────────────────────────────────────
echo ""
echo "[DOWNLOAD] Scaricamento del progetto da GitHub..."

if command -v git &>/dev/null; then
    echo "[INFO] Uso git clone..."
    git clone "$REPO_URL" "$INSTALL_DIR" || {
        echo "[AVVISO] git clone fallito, provo con download ZIP..."
        _use_zip=1
    }
else
    _use_zip=1
fi

if [[ "${_use_zip:-0}" == "1" ]]; then
    echo "[INFO] Download ZIP..."
    TMP_ZIP=$(mktemp /tmp/generai_XXXXXX.zip)
    TMP_DIR=$(mktemp -d /tmp/generai_extract_XXXXXX)

    if command -v curl &>/dev/null; then
        curl -L -o "$TMP_ZIP" "$REPO_ZIP"
    elif command -v wget &>/dev/null; then
        wget -O "$TMP_ZIP" "$REPO_ZIP"
    else
        echo "[ERRORE] Nessun tool di download trovato (curl/wget/git)."
        echo "  Installa curl: sudo apt install curl"
        exit 1
    fi

    unzip -q "$TMP_ZIP" -d "$TMP_DIR"
    cp -r "$TMP_DIR"/generai-1.1-main/. "$INSTALL_DIR/"
    rm -rf "$TMP_ZIP" "$TMP_DIR"
fi

echo "[OK] Progetto scaricato."

# ──────────────────────────────────────────────────────────────
#   4. Crea cartella conversazioni
# ──────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_DIR/conversazioni"
echo "[OK] Cartella conversazioni creata."

# ──────────────────────────────────────────────────────────────
#   5. Scarica il modello AI (GGUF, ~1.3 GB)
# ──────────────────────────────────────────────────────────────
echo ""
if [[ -f "$INSTALL_DIR/$GGUF_NAME" ]]; then
    echo "[OK] Modello AI già presente, salto il download."
else
    read -rp "Scaricare il modello AI (~1.3 GB)? [S/n]: " DOWNLOAD_MODEL
    if [[ "${DOWNLOAD_MODEL,,}" != "n" ]]; then
        echo "[DOWNLOAD] Scaricamento modello AI... Potrebbe richiedere diversi minuti."
        if command -v curl &>/dev/null; then
            curl -L --progress-bar -o "$INSTALL_DIR/$GGUF_NAME" "$GGUF_URL" || {
                echo "[AVVISO] Download modello fallito."
                echo "  Scaricalo manualmente da: $GGUF_URL"
                echo "  Posizionalo in: $INSTALL_DIR/"
            }
        else
            wget --show-progress -O "$INSTALL_DIR/$GGUF_NAME" "$GGUF_URL" || {
                echo "[AVVISO] Download modello fallito."
                echo "  URL: $GGUF_URL"
            }
        fi
        echo "[OK] Modello AI scaricato."
    else
        echo "[SKIP] Modello saltato. Scaricalo e mettilo in: $INSTALL_DIR/"
    fi
fi

# ──────────────────────────────────────────────────────────────
#   6. Ambiente virtuale Python e dipendenze
# ──────────────────────────────────────────────────────────────
echo ""
echo "[SETUP] Creazione ambiente virtuale Python..."
cd "$INSTALL_DIR"
python3 -m venv venv
echo "[OK] Ambiente virtuale creato."

echo "[SETUP] Installazione dipendenze..."
source "$INSTALL_DIR/venv/bin/activate"
pip install --upgrade pip -q
pip install -r "$INSTALL_DIR/requirements.txt"
echo "[OK] Dipendenze installate."

# ──────────────────────────────────────────────────────────────
#   7. Rendi start.sh eseguibile
# ──────────────────────────────────────────────────────────────
chmod +x "$INSTALL_DIR/start.sh" 2>/dev/null || true

# ──────────────────────────────────────────────────────────────
#   Installazione completata!
# ──────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  INSTALLAZIONE COMPLETATA!"
echo "  Cartella: $INSTALL_DIR"
echo "  Avvio:    cd \"$INSTALL_DIR\" && ./start.sh"
echo "══════════════════════════════════════════════════════════════"
echo ""
read -rp "Avviare GenerAI adesso? [S/n]: " LAUNCH_NOW
if [[ "${LAUNCH_NOW,,}" != "n" ]]; then
    bash "$INSTALL_DIR/start.sh"
fi
