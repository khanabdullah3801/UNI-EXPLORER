// ── Navbar scroll effect ──────────────────────────────────────────────
window.addEventListener('scroll', () => {
    const nav = document.getElementById('mainNav');
    if (!nav) return;
    nav.style.boxShadow = window.scrollY > 20 ? '0 4px 20px rgba(0,0,0,0.1)' : '';
});

// ── Toast notifications ───────────────────────────────────────────────
function showToast(msg, duration = 3000) {
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }
    const toast = document.createElement('div');
    toast.className = 'toast-msg d-flex align-items-center gap-2';
    toast.innerHTML = msg;
    container.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.3s';
        setTimeout(() => toast.remove(), 300);
    }, duration);
}

// ── Favorites (localStorage) ──────────────────────────────────────────
function saveFavorite(id, name) {
    let favs = JSON.parse(localStorage.getItem('fav_unis') || '[]');
    if (!favs.includes(id)) {
        favs.push(id);
        localStorage.setItem('fav_unis', JSON.stringify(favs));
        showToast(`<i class="fas fa-heart text-danger"></i> ${name} saved to favorites!`);
    } else {
        showToast(`<i class="fas fa-info-circle text-primary"></i> Already in your favorites!`);
    }
}

// ── Active nav link ───────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
    const path = window.location.pathname;
    document.querySelectorAll('.nav-link').forEach(link => {
        const href = link.getAttribute('href');
        if (href === path || (href !== '/' && path.startsWith(href))) {
            link.classList.add('active');
            link.style.color = 'var(--primary)';
            link.style.background = 'var(--primary-light)';
        }
    });
});
