document.addEventListener('DOMContentLoaded', () => {
    const chatContainer = document.getElementById('chat-container');
    const chatInput = document.getElementById('chat-input');
    const sendBtn = document.getElementById('send-btn');
    const imageUpload = document.getElementById('image-upload');
    const previewContainer = document.getElementById('preview-container');
    const modelStatus = document.getElementById('model-status');
    const statusDot = document.querySelector('.status-dot');


    // --- CONFIGURATION ---
    const API_URL = `http://${window.location.host}/v1/chat/completions`;
    const MODEL_NAME = 'qwen3.5-9b'; // Default model name

    let currentImageData = null;

    // --- INITIALIZATION ---
    async function checkServerStatus() {
        try {
            const response = await fetch(`http://${window.location.host}/v1/models`, { method: 'GET' });
            if (response.ok) {
                statusDot.classList.remove('offline');
                modelStatus.textContent = 'GenerAI (Motore Interno)';
                modelStatus.title = "Il motore AI è pronto a ricevere richieste.";
            } else {
                throw new Error();
            }
        } catch {
            statusDot.classList.add('offline');
            modelStatus.innerHTML = 'AI Engine <span style="color:#ff4d4d; font-weight:bold;">Offline</span>';
            modelStatus.title = "Il server Python non ha caricato il modello.";
            modelStatus.style.cursor = "help";
        }
    }

    // Add click listener for help when offline
    modelStatus.addEventListener('click', () => {
        if (statusDot.classList.contains('offline')) {
            alert("⚠️ MOTORE INTERNO NON PRONTO\n\n1. Assicurati di avere il file 'Qwen3.5-9B-Q4_K_M.gguf' nella cartella.\n2. Verifica di aver installato 'llama-cpp-python'.\n3. Controlla il terminale per eventuali errori di caricamento.");
        }
    });

    checkServerStatus();
    // Re-check every 30 seconds
    setInterval(checkServerStatus, 30000);

    // Handle image upload and preview
    imageUpload.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = (readerEvent) => {
                currentImageData = readerEvent.target.result;
                
                // Show preview
                previewContainer.style.display = 'flex';
                previewContainer.innerHTML = `
                    <div class="preview-wrapper">
                        <img src="${currentImageData}" class="preview-img">
                        <button class="remove-preview" title="Rimuovi">&times;</button>
                    </div>
                `;

                // Handle remove
                previewContainer.querySelector('.remove-preview').addEventListener('click', () => {
                    currentImageData = null;
                    previewContainer.style.display = 'none';
                    imageUpload.value = '';
                });
            };
            reader.readAsDataURL(file);
        }
    });

    // Estrae TUTTI i blocchi pensiero dal testo (think + thought, anche orfani)
    // Restituisce { thought: string, response: string }
    function extractThought(text) {
        const parts = [];
        let response = text;

        // 1. Blocchi completi <think>...</think>
        response = response.replace(/<think>([\s\S]*?)<\/think>/gi, (_, c) => { parts.push(c.trim()); return ''; });
        // 2. Blocchi completi <thought>...</thought>
        response = response.replace(/<thought>([\s\S]*?)<\/thought>/gi, (_, c) => { parts.push(c.trim()); return ''; });
        // 3. Testo prima di un </think> o </thought> senza tag di apertura (il modello ha iniziato a ragionare prima del tag)
        response = response.replace(/^([\s\S]*?)(?:<\/think>|<\/thought>)/i, (_, c) => { if (c.trim()) parts.push(c.trim()); return ''; });
        // 4. Rimuovi eventuali tag rimasti
        response = response.replace(/<\/?(?:think|thought)>/gi, '').trim();

        return { thought: parts.join('\n\n'), response };
    }

    function buildThoughtBubble(thoughtText) {
        const container = document.createElement('div');
        container.className = 'thought-container';

        const header = document.createElement('div');
        header.className = 'thought-header';
        header.innerHTML = '<i class="fas fa-brain"></i> RAGIONAMENTO <i class="fas fa-chevron-down thought-chevron"></i>';

        const bubble = document.createElement('div');
        bubble.className = 'thought-bubble';
        bubble.innerHTML = thoughtText.replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g, '<br>');

        header.addEventListener('click', () => container.classList.toggle('open'));
        container.appendChild(header);
        container.appendChild(bubble);
        return container;
    }

    const addMessage = (text, isAi = false, imageData = null) => {
        const msgDiv = document.createElement('div');
        msgDiv.className = `message ${isAi ? 'ai-message' : 'user-message'}`;
        
        if (imageData) {
            const img = document.createElement('img');
            img.src = imageData;
            img.className = 'message-image';
            msgDiv.appendChild(img);
        }
        
        if (text) {
            let displayText = text;

            if (isAi) {
                const { thought, response } = extractThought(displayText);
                displayText = response;
                if (thought) msgDiv.appendChild(buildThoughtBubble(thought));
            }

            // Rendering testo + code block
            if (isAi && displayText.includes('```')) {
                const parts = displayText.split('```');
                parts.forEach((part, index) => {
                    if (index % 2 === 1) {
                        const pre = document.createElement('pre');
                        pre.style.background = 'rgba(0,0,0,0.3)';
                        pre.style.padding = '1rem';
                        pre.style.borderRadius = '8px';
                        pre.style.margin = '1rem 0';
                        pre.style.overflowX = 'auto';
                        pre.textContent = part.trim();
                        msgDiv.appendChild(pre);
                    } else if (part) {
                        const span = document.createElement('span');
                        span.style.whiteSpace = 'pre-wrap';
                        span.textContent = part;
                        msgDiv.appendChild(span);
                    }
                });
            } else {
                const p = document.createElement('p');
                p.textContent = displayText;
                msgDiv.appendChild(p);
            }
        }

        chatContainer.appendChild(msgDiv);
        chatContainer.scrollTo({
            top: chatContainer.scrollHeight,
            behavior: 'smooth'
        });
        return msgDiv;
    };

    const showTyping = () => {
        const typingDiv = document.createElement('div');
        typingDiv.className = 'message ai-message';
        typingDiv.innerHTML = '<div class="typing"><span></span><span></span><span></span></div>';
        chatContainer.appendChild(typingDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight;
        return typingDiv;
    };

    const sendMessage = async () => {
        const text = chatInput.value.trim();
        if (!text && !currentImageData) return;

        // Add user message to UI
        addMessage(text, false, currentImageData);
        
        // Save references before clearing
        const savedText = text;
        const savedImageData = currentImageData;

        // Clear input and previews immediately for better UX
        chatInput.value = '';
        currentImageData = null;
        previewContainer.style.display = 'none';
        imageUpload.value = '';
        sendBtn.disabled = true;
        chatInput.placeholder = "Generazione in corso...";

        const typingIndicator = showTyping();

        // Prepare request data
        let messages = [{ role: 'user', content: savedText }];
        
        // Think mode sempre attivo
        messages.unshift({
            role: 'system',
            content: "Sei un assistente AI avanzato. Prima di rispondere, scrivi il tuo ragionamento interno passo-passo tra i tag <thought> e </thought>. Poi scrivi la risposta finale."
        });

        if (savedImageData) {
            messages[0].content = [
                { type: 'text', text: savedText || "Analizza questa immagine" },
                { type: 'image_url', image_url: { url: savedImageData } }
            ];
        }

        try {
            const response = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: MODEL_NAME,
                    messages,
                    temperature: 0.7,
                    max_tokens: 2000,
                    stream: true
                })
            });

            if (!response.ok) {
                typingIndicator.remove();
                const err = await response.json().catch(() => ({}));
                addMessage(`⚠ Errore server (HTTP ${response.status})\n${err?.error?.message || ''}`, true);
                return;
            }

            // Prepara div live per lo streaming
            typingIndicator.remove();
            const aiDiv = document.createElement('div');
            aiDiv.className = 'message ai-message';
            chatContainer.appendChild(aiDiv);

            // Elementi live
            const thinkingEl = document.createElement('div');
            thinkingEl.className = 'thought-container';
            thinkingEl.innerHTML = '<div class="thought-header"><i class="fas fa-brain"></i> Ragionando... <i class="fas fa-chevron-down thought-chevron"></i></div><div class="thought-bubble" style="max-height:none;opacity:1;padding:0.5rem 1.2rem;font-style:italic;color:var(--text-muted)"></div>';
            const thinkingBubble = thinkingEl.querySelector('.thought-bubble');
            const liveEl = document.createElement('span');
            liveEl.style.whiteSpace = 'pre-wrap';

            const reader = response.body.getReader();
            const decoder = new TextDecoder();
            let buf = '', fullText = '', inThought = false;
            let thoughtDone = false;

            outer: while (true) {
                const { done, value } = await reader.read();
                if (done) break;
                buf += decoder.decode(value, { stream: true });
                const lines = buf.split('\n');
                buf = lines.pop();
                for (const line of lines) {
                    if (!line.startsWith('data: ')) continue;
                    const raw = line.slice(6).trim();
                    if (raw === '[DONE]') break outer;
                    try {
                        const delta = JSON.parse(raw).choices?.[0]?.delta?.content || '';
                        if (!delta) continue;
                        fullText += delta;

                        // Rileva inizio blocco pensiero
                        if (!inThought && !thoughtDone && /<think|<thought/i.test(fullText)) {
                            inThought = true;
                            if (!aiDiv.contains(thinkingEl)) aiDiv.appendChild(thinkingEl);
                        }

                        if (inThought) {
                            // Mostra il pensiero live (tutto il testo prima del tag di chiusura)
                            const endMatch = fullText.match(/(?:<think>|^)([\s\S]*?)(?:<\/think>|<\/thought>)/i);
                            if (endMatch) {
                                inThought = false;
                                thoughtDone = true;
                                thinkingBubble.innerHTML = endMatch[1].replace(/<\/?(?:think|thought)>/gi,'').trim().replace(/\n/g,'<br>');
                                const h = thinkingEl.querySelector('.thought-header');
                                h.innerHTML = '<i class="fas fa-brain"></i> RAGIONAMENTO <i class="fas fa-chevron-down thought-chevron"></i>';
                                h.addEventListener('click', () => thinkingEl.classList.toggle('open'));
                                if (!aiDiv.contains(liveEl)) aiDiv.appendChild(liveEl);
                            } else {
                                // Ancora in corso: mostra tutto come testo pensiero
                                thinkingBubble.innerHTML = fullText.replace(/<\/?(?:think|thought)>/gi,'').trim().replace(/\n/g,'<br>');
                            }
                        } else {
                            const { response } = extractThought(fullText);
                            if (!aiDiv.contains(liveEl)) aiDiv.appendChild(liveEl);
                            liveEl.textContent = response;
                        }

                        chatContainer.scrollTop = chatContainer.scrollHeight;
                    } catch { /* chunk malformato */ }
                }
            }

            // Render finale in-place
            aiDiv.innerHTML = '';
            const { thought: ft, response: display } = extractThought(fullText);
            if (ft) aiDiv.appendChild(buildThoughtBubble(ft));
            if (display.includes('```')) {
                display.split('```').forEach((part, i) => {
                    if (i % 2 === 1) {
                        const pre = document.createElement('pre');
                        pre.style.cssText = 'background:rgba(0,0,0,0.3);padding:1rem;border-radius:8px;margin:1rem 0;overflow-x:auto;';
                        pre.textContent = part.trim();
                        aiDiv.appendChild(pre);
                    } else if (part) {
                        const s = document.createElement('span');
                        s.style.whiteSpace = 'pre-wrap';
                        s.textContent = part;
                        aiDiv.appendChild(s);
                    }
                });
            } else {
                const p = document.createElement('p');
                p.textContent = display;
                aiDiv.appendChild(p);
            }
            chatContainer.scrollTo({ top: chatContainer.scrollHeight, behavior: 'smooth' });

        } catch (error) {
            typingIndicator.remove();
            const errorMsg = error.name === 'TypeError'
                ? `⚠ Server non raggiungibile\n${error.message}`
                : `⚠ Errore (${error.name}): ${error.message}`;
            addMessage(errorMsg, true);
        } finally {
            sendBtn.disabled = false;
            chatInput.disabled = false;
            chatInput.placeholder = "Chiedi qualsiasi cosa a GenerAI...";
            chatInput.focus();
            checkServerStatus(); // Update dot status after attempt
        }
    };

    sendBtn.addEventListener('click', sendMessage);
    chatInput.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            sendMessage();
        }
    });

    // Handle paste for images
    chatInput.addEventListener('paste', (e) => {
        const items = e.clipboardData.items;
        for (let i = 0; i < items.length; i++) {
            if (items[i].type.indexOf('image') !== -1) {
                const blob = items[i].getAsFile();
                const reader = new FileReader();
                reader.onload = (event) => {
                    currentImageData = event.target.result;
                    previewContainer.style.display = 'flex';
                    previewContainer.innerHTML = `
                        <div class="preview-wrapper">
                            <img src="${currentImageData}" class="preview-img">
                            <button class="remove-preview">&times;</button>
                        </div>
                    `;
                    previewContainer.querySelector('.remove-preview').onclick = () => {
                        currentImageData = null;
                        previewContainer.style.display = 'none';
                    };
                };
                reader.readAsDataURL(blob);
            }
        }
    });
});
