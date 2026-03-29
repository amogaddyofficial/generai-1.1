# 🚀 GenerAI Studio Premium (Standalone)

GenerAI Studio è un ambiente di sviluppo e chat AI **completamente indipendente**. Non richiede LM Studio, Ollama o connessioni internet per funzionare. Tutto il processamento avviene localmente tramite il motore integrato.

## ✨ Caratteristiche Principal

- **Motore AI Built-in**: Basato su `llama-cpp-python` per caricare direttamente i file GGUF.
- **IDE Integrato**: Editor di codice professionale con assistente dedicato.
- **Multimodale**: Supporto per l'analisi delle immagini (se il modello vision è presente).
- **Privacy Totale**: I tuoi dati non lasciano mai il tuo computer.

## 🛠️ Requisiti di Sistema

- **Python 3.10+** installato e nel PATH.
- **RAM**: Minimo 8GB (Consigliati 16GB per Qwen 9B).
- **Hardware**: Funziona su CPU, ma supporta accelerazione GPU (CUDA) se configurata.

## 🚀 Come Iniziare

1.  Assicurati che il file del modello `Qwen3.5-9B-Q4_K_M.gguf` sia nella cartella principale.
2.  Esegui `start.bat`.
3.  Al primo avvio, il sistema installerà automaticamente le dipendenze mancanti.
4.  Attendi il caricamento del modello (vedrai i messaggi nel terminale).
5.  Il browser si aprirà automaticamente su `http://localhost:8000`.

## 📂 Struttura del Progetto

- `server.py`: Il cuore del sistema (Web + AI Server).
- `index.html`: Dashboard Chat Premium.
- `editor.html`: Ambiente di sviluppo IDE.
- `start.bat`: Script di avvio rapido e setup automatico.

---
*Powered by GenerAI Engine & Qwen 3.5 9B*
