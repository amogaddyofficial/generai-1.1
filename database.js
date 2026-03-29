document.addEventListener('DOMContentLoaded', () => {
    const dropZone = document.getElementById('drop-zone');
    const dbUpload = document.getElementById('db-upload');
    const uploadView = document.getElementById('upload-view');
    const dataView = document.getElementById('data-view');
    const tableHeader = document.getElementById('table-header');
    const tableBody = document.getElementById('table-body');
    const statRows = document.getElementById('stat-rows');
    const statCols = document.getElementById('stat-cols');
    const statFilename = document.getElementById('stat-filename');
    
    // AI Related
    const aiInput = document.getElementById('ai-input');
    const aiSend = document.getElementById('ai-send');
    const aiMessages = document.getElementById('ai-messages');
    
    let currentData = null;
    let dataContext = ""; // Summary for the AI
    const API_URL = `http://${window.location.host}/v1/chat/completions`;

    // --- ERROR DISPLAY ---
    const showErrorInChat = (title, details) => {
        const msg = document.createElement('div');
        msg.className = 'message ai-message';
        msg.style.cssText = 'font-size:0.82rem; border-left: 3px solid #f43f5e;';
        msg.innerHTML = `<strong style="color:#f43f5e;">⚠ ${title}</strong><pre style="margin-top:0.5rem; white-space:pre-wrap; opacity:0.8; font-size:0.75rem;">${details}</pre>`;
        aiMessages.appendChild(msg);
        aiMessages.scrollTop = aiMessages.scrollHeight;
    };

    // --- FILE HANDLING ---
    const processFile = (file) => {
        const reader = new FileReader();
        const extension = file.name.split('.').pop().toLowerCase();

        reader.onerror = () => {
            alert(`Errore lettura file "${file.name}"\nTipo errore: ${reader.error?.name}\nDettaglio: ${reader.error?.message}`);
        };

        reader.onload = (e) => {
            const data = e.target.result;
            try {
                if (extension === 'json') {
                    renderJSON(JSON.parse(data), file.name);
                } else if (extension === 'csv') {
                    const workbook = XLSX.read(data, { type: 'string' });
                    const firstSheet = workbook.SheetNames[0];
                    const jsonData = XLSX.utils.sheet_to_json(workbook.Sheets[firstSheet]);
                    renderTable(jsonData, file.name);
                } else {
                    const workbook = XLSX.read(data, { type: 'array' });
                    const firstSheet = workbook.SheetNames[0];
                    const jsonData = XLSX.utils.sheet_to_json(workbook.Sheets[firstSheet]);
                    renderTable(jsonData, file.name);
                }
            } catch (err) {
                console.error('[DATABASE] Errore caricamento file:', err);
                alert(`Errore nel caricamento di "${file.name}"\n\nTipo: ${err.name}\nDettaglio: ${err.message}\n\nFormato supportati: .xlsx, .xls, .csv, .json`);
            }
        };

        if (extension === 'json') {
            reader.readAsText(file);
        } else if (extension === 'csv') {
            reader.readAsText(file);
        } else {
            reader.readAsArrayBuffer(file);
        }
    };

    const renderJSON = (data, filename) => {
        const arrayData = Array.isArray(data) ? data : [data];
        renderTable(arrayData, filename);
    };

    const renderTable = (data, filename) => {
        if (!data || data.length === 0) return;
        currentData = data;
        statFilename.textContent = filename;
        statRows.textContent = data.length;
        statCols.textContent = Object.keys(data[0]).length;
        
        // Render Header
        const headers = Object.keys(data[0]);
        tableHeader.innerHTML = headers.map(h => `<th>${h}</th>`).join('');
        
        // Render Body (limit to 100 rows for performance)
        tableBody.innerHTML = data.slice(0, 100).map(row => {
            return `<tr>${headers.map(h => `<td>${row[h] || ''}</td>`).join('')}</tr>`;
        }).join('');

        // Prepare context for AI (Column names + Very small sample)
        const sampleRows = data.slice(0, 2);
        dataContext = `FILE: ${filename}\nCOLONNE: ${headers.join(', ')}\nRIGHE TOTALI: ${data.length}\nESEMPIO DATI (Primi 2 righe): \n${JSON.stringify(sampleRows, null, 2)}`;
        
        uploadView.style.display = 'none';
        dataView.style.display = 'flex';
    };

    // Drag and Drop
    dropZone.onclick = () => dbUpload.click();
    dbUpload.onchange = (e) => processFile(e.target.files[0]);
    
    dropZone.ondragover = (e) => { e.preventDefault(); dropZone.classList.add('drag-over'); };
    dropZone.ondragleave = () => dropZone.classList.remove('drag-over');
    dropZone.ondrop = (e) => {
        e.preventDefault();
        dropZone.classList.remove('drag-over');
        if (e.dataTransfer.files.length) processFile(e.dataTransfer.files[0]);
    };

    // --- AI ANALYSIS ---
    const addAiMessage = (text, isAi = false) => {
        const msg = document.createElement('div');
        msg.className = `message ${isAi ? 'ai-message' : 'user-message'}`;
        msg.style.fontSize = '0.85rem';
        msg.textContent = text;
        aiMessages.appendChild(msg);
        aiMessages.scrollTop = aiMessages.scrollHeight;
        return msg;
    };

    const runAnalysis = async () => {
        const query = aiInput.value.trim();
        if (!query || !currentData) return;

        addAiMessage(query, false);
        aiInput.value = "";
        aiInput.disabled = true;

        const typing = addAiMessage("Analizzando i dati...", true);

        try {
            const systemPrompt = `Sei un esperto di analisi dati. Il tuo compito è rispondere a domande basandoti sui dati forniti. \n${dataContext}\n\nAnalizza e fornisci risposte concise.`;

            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    messages: [
                        { role: 'system', content: systemPrompt },
                        { role: 'user', content: query }
                    ],
                    temperature: 0.2
                })
            });

            typing.remove();
            const rawText = await response.text();
            let result;
            try { result = JSON.parse(rawText); } catch {
                showErrorInChat('Risposta non valida dal server', `HTTP ${response.status}\n\n${rawText.slice(0, 500)}`);
                return;
            }

            if (!response.ok || result.error) {
                const msg = result.error?.message || result.error || 'Errore sconosciuto';
                showErrorInChat(`Errore server (HTTP ${response.status})`, msg);
            } else {
                addAiMessage(result.choices[0].message.content, true);
            }

        } catch (err) {
            typing.remove();
            console.error('[DATABASE] Errore richiesta AI:', err);
            const isFetchError = err.name === 'TypeError' && err.message.includes('fetch');
            showErrorInChat(
                isFetchError ? 'Server non raggiungibile' : `Errore JS: ${err.name}`,
                isFetchError ? `Impossibile contattare ${API_URL}\nAssicurati che server.py sia in esecuzione.` : err.message
            );
        } finally {
            aiInput.disabled = false;
            aiInput.focus();
        }
    };

    aiSend.onclick = runAnalysis;
    aiInput.onkeypress = (e) => { if (e.key === 'Enter') runAnalysis(); };

    // --- BOOTSTRAP STATUS ---
    async function checkServerStatus() {
        const statusDot = document.querySelector('.status-dot');
        const modelStatus = document.getElementById('model-status');
        try {
            const res = await fetch(`http://${window.location.host}/v1/models`);
            if (res.ok) {
                statusDot.classList.remove('offline');
                modelStatus.textContent = 'AI Caricata';
                modelStatus.title = '';
            } else {
                const body = await res.text().catch(() => '');
                statusDot.classList.add('offline');
                modelStatus.textContent = `Server Errore (HTTP ${res.status})`;
                modelStatus.title = body.slice(0, 200);
            }
        } catch (err) {
            statusDot.classList.add('offline');
            modelStatus.textContent = 'Server Offline';
            modelStatus.title = err.message;
        }
    }
    checkServerStatus();
});
