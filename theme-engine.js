// GenerAI Theme Engine
const themes = {
    amethyst: { name: 'Amethyst', class: '' },
    emerald: { name: 'Emerald', class: 'theme-emerald' },
    sapphire: { name: 'Sapphire', class: 'theme-sapphire' },
    crimson: { name: 'Crimson', class: 'theme-crimson' },
    ghost: { name: 'Ghost', class: 'theme-ghost' }
};

function applyTheme(themeKey) {
    const body = document.body;
    // Remove all theme classes
    Object.values(themes).forEach(t => {
        if (t.class) body.classList.remove(t.class);
    });
    
    // Add new theme class
    const theme = themes[themeKey];
    if (theme && theme.class) {
        body.classList.add(theme.class);
    }
    
    // Save to localStorage
    localStorage.setItem('generai-theme', themeKey);
    
    // Update active state in UI if modal is open
    updateThemeTiles(themeKey);
}

function updateThemeTiles(activeKey) {
    const tiles = document.querySelectorAll('.theme-tile');
    tiles.forEach(tile => {
        if (tile.dataset.theme === activeKey) {
            tile.classList.add('active');
        } else {
            tile.classList.remove('active');
        }
    });
}

function initTheme() {
    const savedTheme = localStorage.getItem('generai-theme') || 'amethyst';
    applyTheme(savedTheme);
}

// Modal Toggle Logic
function toggleSettingsModal(show) {
    const modal = document.getElementById('settings-modal-overlay');
    if (!modal) return;
    modal.style.display = show ? 'flex' : 'none';
}

// Initialize on load
document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    
    // Add close listener if modal exists
    const closeBtn = document.querySelector('.close-modal');
    if (closeBtn) {
        closeBtn.onclick = () => toggleSettingsModal(false);
    }
    
    const overlay = document.getElementById('settings-modal-overlay');
    if (overlay) {
        overlay.onclick = (e) => {
            if (e.target === overlay) toggleSettingsModal(false);
        };
    }
});
