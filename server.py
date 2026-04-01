from pathlib import Path
import os, sys, json, http.server, webbrowser, urllib.parse

# ────────────────────────────────────────────
#  PERCORSI DINAMICI (funziona su qualsiasi PC)
# ────────────────────────────────────────────
BASE_DIR = Path(__file__).resolve().parent
MODEL_NAME = "Qwen3.5-9B-Q4_K_M.gguf"

def find_model():
    """Cerca il modello GGUF in posizioni relative al progetto."""
    paths_to_try = [
        BASE_DIR / MODEL_NAME,                          # Stessa cartella di server.py
        BASE_DIR / "models" / MODEL_NAME,               # Sotto-cartella models/
        Path(os.path.expanduser("~")) / MODEL_NAME,     # Home utente (fallback)
    ]

    for path in paths_to_try:
        if path.exists() and path.stat().st_size > 100 * 1024 * 1024:
            print(f"[OK] Modello trovato: {path}")
            return str(path)

    print(f"[!] Modello '{MODEL_NAME}' non trovato.")
    print(f"    Cercato in:")
    for p in paths_to_try:
        print(f"      - {p}")
    return None

def load_model():
    """Carica il modello con llama-cpp-python."""
    model_path = find_model()
    if not model_path:
        return None

    try:
        from llama_cpp import Llama
        llm = Llama(
            model_path=model_path,
            n_ctx=4096,
            verbose=False,
            low_vram=False
        )
        print(f"[OK] Motore AI caricato con successo!")
        return llm
    except ImportError:
        print("[!] llama-cpp-python non installato. Avvio senza motore AI.")
        return None
    except Exception as e:
        print(f"[ERRORE] Caricamento modello fallito: {e}")
        return None

# ────────────────────────────────────────────
#  HTTP HANDLER (serve file + API)
# ────────────────────────────────────────────
llm_engine = None

class GenerAIHandler(http.server.SimpleHTTPRequestHandler):
    """Handler HTTP che serve file statici e API per il motore AI."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(BASE_DIR), **kwargs)

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/v1/models":
            self._send_json({"data": [{"id": "qwen3.5-9b", "object": "model"}]} if llm_engine else {"data": []})
            return

        # Serve file statici
        super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)

        if parsed.path == "/v1/chat/completions":
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length)

            if not llm_engine:
                self._send_json({"error": {"message": "Motore AI non caricato."}}, status=503)
                return

            try:
                data = json.loads(body)
                messages = data.get("messages", [])
                temperature = data.get("temperature", 0.7)
                max_tokens = data.get("max_tokens", 2000)
                stream = data.get("stream", False)

                if stream:
                    self._handle_stream(messages, temperature, max_tokens)
                else:
                    response = llm_engine.create_chat_completion(
                        messages=messages,
                        temperature=temperature,
                        max_tokens=max_tokens
                    )
                    self._send_json(response)

            except Exception as e:
                self._send_json({"error": {"message": str(e)}}, status=500)
            return

        self._send_json({"error": {"message": "Endpoint non trovato"}}, status=404)

    def _handle_stream(self, messages, temperature, max_tokens):
        """Gestione streaming SSE."""
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()

        try:
            stream = llm_engine.create_chat_completion(
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                stream=True
            )
            for chunk in stream:
                chunk_json = json.dumps(chunk)
                self.wfile.write(f"data: {chunk_json}\n\n".encode())
                self.wfile.flush()

            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
        except Exception as e:
            error_chunk = json.dumps({"error": {"message": str(e)}})
            self.wfile.write(f"data: {error_chunk}\n\n".encode())
            self.wfile.flush()

    def _send_json(self, data, status=200):
        """Invia risposta JSON."""
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def do_OPTIONS(self):
        """CORS preflight."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def log_message(self, format, *args):
        """Silenzia i log HTTP normali, mostra solo errori."""
        if args and "404" in str(args[0]):
            super().log_message(format, *args)

# ────────────────────────────────────────────
#  MAIN
# ────────────────────────────────────────────
if __name__ == "__main__":
    PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000

    # Assicurati che la cartella conversazioni esista
    conv_dir = BASE_DIR / "conversazioni"
    conv_dir.mkdir(exist_ok=True)

    print(f"\n{'='*50}")
    print(f"  GENERAI STUDIO v1.1 - Avvio...")
    print(f"  Cartella progetto: {BASE_DIR}")
    print(f"{'='*50}\n")

    # Carica motore AI
    llm_engine = load_model()

    url = f"http://localhost:{PORT}"

    try:
        with http.server.HTTPServer(("", PORT), GenerAIHandler) as httpd:
            print(f"\n{'='*50}")
            print(f"  GENERAI STUDIO ATTIVO")
            print(f"  URL: {url}")
            print(f"  MOTORE AI: {'PRONTO' if llm_engine else 'OFFLINE (solo interfaccia)'}")
            print(f"{'='*50}\n")
            webbrowser.open(url)
            httpd.serve_forever()
    except OSError as e:
        if "10048" in str(e) or "address already in use" in str(e).lower():
            print(f"\n[ERRORE] La porta {PORT} e' gia' in uso!")
            print(f"  Chiudi l'altra istanza o usa una porta diversa.")
        else:
            print(f"\n[ERRORE] {e}")
    except KeyboardInterrupt:
        print("\n[INFO] Server fermato.")
