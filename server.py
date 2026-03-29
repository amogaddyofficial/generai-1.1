import http.server
import socketserver
import webbrowser
import os
import socket
import sys
import json
import time

try:
    from ddgs import DDGS
    HAS_DDGS = True
except ImportError:
    HAS_DDGS = False

# --- CONFIGURATION ---
PORT = 8000
if len(sys.argv) > 1:
    try:
        PORT = int(sys.argv[1])
    except ValueError:
        pass

DIRECTORY = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(DIRECTORY, "Qwen3.5-9B-Q4_K_M.gguf")

# Global LLM instance
llm = None

def load_model():
    global llm
    try:
        from llama_cpp import Llama
        if os.path.exists(MODEL_PATH):
            print(f"[INFO] Caricamento del modello: {os.path.basename(MODEL_PATH)}...")
            llm = Llama(
                model_path=MODEL_PATH,
                n_ctx=2048,
                n_threads=os.cpu_count(),
                n_threads_batch=os.cpu_count(),
                n_batch=512,
                verbose=False,
                use_mmap=True,
            )
            print("[SUCCESS] Modello AI caricato correttamente.")
        else:
            print(f"[WARNING] Modello non trovato in: {MODEL_PATH}")
    except Exception as e:
        print(f"[ERROR] Impossibile inizializzare il motore AI: {e}")

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        if self.path in ('/', ''):
            self.path = '/index.html'
        elif self.path == '/download':
            self.send_response(302)
            self.send_header('Location', '/download.html')
            self.end_headers()
            return
        elif self.path == '/v1/models':
            models = [{'id': os.path.basename(MODEL_PATH), 'object': 'model'}] if llm else []
            self._send_json(200, {'object': 'list', 'data': models})
            return
        elif self.path == '/api/conversations':
            conv_dir = os.path.join(DIRECTORY, 'conversazioni')
            os.makedirs(conv_dir, exist_ok=True)
            files = sorted(
                [f for f in os.listdir(conv_dir) if f.endswith('.json')],
                reverse=True
            )
            self._send_json(200, files)
            return
        elif self.path.startswith('/api/conversations/'):
            fname = os.path.basename(self.path)
            fpath = os.path.join(DIRECTORY, 'conversazioni', fname)
            if not os.path.exists(fpath):
                self._send_json(404, {'error': 'non trovato'})
                return
            with open(fpath, 'r', encoding='utf-8') as f:
                self._send_raw(200, f.read().encode('utf-8'))
            return
        elif self.path == '/api/files':
            result = []
            skip_dirs  = {'__pycache__', 'node_modules', '.git', 'conversazioni'}
            skip_exts  = {'.gguf', '.pyc', '.pyo', '.exe', '.dll', '.so', '.bin'}
            skip_names = {'chunk_gguf_00','chunk_gguf_01','chunk_gguf_02',
                          'chunk_gguf_03','chunk_gguf_04','chunk_gguf_05'}
            for root, dirs, files in os.walk(DIRECTORY):
                dirs[:] = [d for d in dirs if d not in skip_dirs and not d.startswith('.')]
                for fn in sorted(files):
                    if fn.startswith('.') or fn in skip_names:
                        continue
                    if os.path.splitext(fn)[1].lower() in skip_exts:
                        continue
                    rel = os.path.relpath(os.path.join(root, fn), DIRECTORY).replace('\\', '/')
                    result.append(rel)
            self._send_json(200, result)
            return
        elif self.path.startswith('/api/file?'):
            from urllib.parse import urlparse, parse_qs
            qs = parse_qs(urlparse(self.path).query)
            rel = qs.get('path', [''])[0]
            full = os.path.normpath(os.path.join(DIRECTORY, rel))
            if not full.startswith(os.path.normpath(DIRECTORY)) or not os.path.isfile(full):
                self._send_json(404, {'error': 'non trovato'})
                return
            with open(full, 'r', encoding='utf-8', errors='replace') as f:
                self._send_json(200, {'path': rel, 'content': f.read()})
            return
        super().do_GET()

    def do_POST(self):
        if self.path == '/api/file':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                rel = data.get('path', '')
                content = data.get('content', '')
                full = os.path.normpath(os.path.join(DIRECTORY, rel))
                if not full.startswith(os.path.normpath(DIRECTORY)):
                    self._send_json(403, {'error': 'accesso negato'})
                    return
                os.makedirs(os.path.dirname(full), exist_ok=True)
                with open(full, 'w', encoding='utf-8') as f:
                    f.write(content)
                self._send_json(200, {'saved': rel})
            except Exception as e:
                self._send_json(500, {'error': str(e)})
            return

        if self.path == '/api/conversations':
            length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(length)
            try:
                data = json.loads(body)
                conv_dir = os.path.join(DIRECTORY, 'conversazioni')
                os.makedirs(conv_dir, exist_ok=True)
                fname = data.get('filename', f"chat_{int(time.time())}.json")
                fname = os.path.basename(fname)  # sicurezza: no path traversal
                with open(os.path.join(conv_dir, fname), 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                self._send_json(200, {'saved': fname})
            except Exception as e:
                self._send_json(500, {'error': str(e)})
            return

        if self.path != '/v1/chat/completions':
            self.send_response(404)
            self.end_headers()
            return

        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)

        try:
            req = json.loads(body)
        except json.JSONDecodeError as e:
            self._send_json(400, {'error': {'message': f'JSON non valido: {e}'}})
            return

        if not llm:
            self._send_json(503, {'error': {'message': 'Il motore AI non e\' pronto o il modello manca.'}})
            return

        messages    = req.get('messages', [])
        temperature = req.get('temperature', 0.7)
        max_tokens  = req.get('max_tokens', 2048)
        streaming   = req.get('stream', False)
        web_search  = req.get('web_search', False)

        try:
            if web_search and HAS_DDGS and messages:
                last_user_msg = next((m for m in reversed(messages) if m.get('role') == 'user'), None)
                if last_user_msg:
                    query_text = ""
                    if isinstance(last_user_msg['content'], str):
                        query_text = last_user_msg['content']
                    elif isinstance(last_user_msg['content'], list):
                        for c in last_user_msg['content']:
                            if isinstance(c, dict) and c.get('type') == 'text':
                                query_text += c.get('text', '') + " "

                    if query_text:
                        print(f"[WEB SEARCH] Ricerca in corso per: {query_text[:50]}...")
                        try:
                            results = DDGS().text(query_text.strip(), max_results=3)
                            search_context = "\n\n--- RISULTATI DELLA RICERCA WEB ---\n"
                            for res in results:
                                search_context += f"Titolo: {res.get('title')}\nSnippet: {res.get('body')}\nLink: {res.get('href')}\n\n"
                            search_context += "Usa le informazioni qui sopra per rispondere aggiornato alla domanda dell'utente."

                            if isinstance(last_user_msg['content'], str):
                                last_user_msg['content'] += search_context
                            elif isinstance(last_user_msg['content'], list):
                                last_user_msg['content'].append({'type': 'text', 'text': search_context})
                            print("[WEB SEARCH] Risultati trovati e iniettati.")
                        except Exception as e:
                            print(f"[WEB SEARCH ERROR] Impossibile recuperare i risultati: {e}")

            if streaming:
                self._stream(messages, temperature, max_tokens)
            else:
                result = llm.create_chat_completion(
                    messages=messages,
                    temperature=temperature,
                    max_tokens=max_tokens,
                )
                self._send_json(200, result)
                print("[*] Risposta generata con successo.")
        except BrokenPipeError:
            pass
        except Exception as e:
            print(f'[ERROR] Generazione: {e}')
            try:
                self._send_json(500, {'error': {'message': str(e)}})
            except BrokenPipeError:
                pass

    def _stream(self, messages, temperature, max_tokens):
        self.send_response(200)
        self.send_header('Content-Type', 'text/event-stream')
        self.send_header('Cache-Control', 'no-cache')
        self.end_headers()
        try:
            for chunk in llm.create_chat_completion(
                messages=messages,
                temperature=temperature,
                max_tokens=max_tokens,
                stream=True,
            ):
                self.wfile.write(f'data: {json.dumps(chunk)}\n\n'.encode())
                self.wfile.flush()
            self.wfile.write(b'data: [DONE]\n\n')
            self.wfile.flush()
        except BrokenPipeError:
            pass
        except Exception as e:
            try:
                self.wfile.write(f'data: {json.dumps({"error": {"message": str(e)}})}\n\n'.encode())
                self.wfile.write(b'data: [DONE]\n\n')
                self.wfile.flush()
            except BrokenPipeError:
                pass

    def _send_raw(self, status, body: bytes):
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(body)

    def _send_json(self, status, obj):
        self._send_raw(status, json.dumps(obj).encode('utf-8'))

    def log_message(self, format, *args):
        print(f'[{self.address_string()}] {format % args}')

def is_port_in_use(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(('localhost', port)) == 0

def start_server():
    if is_port_in_use(PORT):
        print(f"[!] Errore: La porta {PORT} e' gia' occupata.")
        input("Premi Invio per uscire...")
        sys.exit(1)

    # Load model FIRST
    load_model()

    os.chdir(DIRECTORY)
    try:
        with socketserver.TCPServer(("", PORT), Handler) as httpd:
            url = f"http://localhost:{PORT}/index.html"
            print("==================================================")
            print(f"  GENERAI STUDIO (STANDALONE) ATTIVO")
            print(f"  URL: {url}")
            print(f"  STATUS MOTORE: {'PRONTO' if llm else 'OFFLINE (Modello non caricato)'}")
            print("==================================================")
            print("[*] Dashboard in apertura...")
            print("[*] Premi Ctrl+C per fermare il programma.")
            print("--------------------------------------------------")
            
            webbrowser.open(url)
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[INFO] Server fermato.")
    except Exception as e:
        print(f"\n[ERRORE] Errore inaspettato: {e}")

if __name__ == "__main__":
    start_server()

