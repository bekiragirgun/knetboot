/**
 * Kapadokya NetBoot - Frontend JavaScript
 * Version: 3.0 (Tabler Edition)
 */

// =============================================================================
// Dark Mode Toggle
// =============================================================================

function initDarkMode() {
    const themeToggle = document.getElementById('theme-toggle');
    const themeIcon = themeToggle?.querySelector('i');

    // Load saved theme or default to light
    const savedTheme = localStorage.getItem('theme') || 'light';
    document.documentElement.setAttribute('data-bs-theme', savedTheme);
    updateThemeIcon(savedTheme, themeIcon);

    // Toggle theme on click
    themeToggle?.addEventListener('click', (e) => {
        e.preventDefault();
        const currentTheme = document.documentElement.getAttribute('data-bs-theme');
        const newTheme = currentTheme === 'dark' ? 'light' : 'dark';

        document.documentElement.setAttribute('data-bs-theme', newTheme);
        localStorage.setItem('theme', newTheme);
        updateThemeIcon(newTheme, themeIcon);

        showToast(`${newTheme === 'dark' ? 'Dark' : 'Light'} mode activated`, 'info');
    });
}

function updateThemeIcon(theme, iconElement) {
    if (!iconElement) return;

    if (theme === 'dark') {
        iconElement.classList.remove('ti-moon');
        iconElement.classList.add('ti-sun');
    } else {
        iconElement.classList.remove('ti-sun');
        iconElement.classList.add('ti-moon');
    }
}

// =============================================================================
// Toast Notifications
// =============================================================================

function showToast(message, type = 'info') {
    // Create toast container if doesn't exist
    let container = document.querySelector('.toast-container');
    if (!container) {
        container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }

    // Icon and color mapping
    const iconMap = {
        success: 'ti-check',
        error: 'ti-alert-circle',
        warning: 'ti-alert-triangle',
        info: 'ti-info-circle'
    };

    const colorMap = {
        success: 'success',
        error: 'danger',
        warning: 'warning',
        info: 'info'
    };

    const icon = iconMap[type] || iconMap.info;
    const color = colorMap[type] || colorMap.info;

    // Create toast element
    const toastEl = document.createElement('div');
    toastEl.className = `toast align-items-center text-bg-${color} border-0`;
    toastEl.setAttribute('role', 'alert');
    toastEl.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">
                <i class="ti ${icon} me-2"></i>
                ${message}
            </div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;

    container.appendChild(toastEl);

    // Show toast
    const toast = new bootstrap.Toast(toastEl, { delay: 4000 });
    toast.show();

    // Remove from DOM after hidden
    toastEl.addEventListener('hidden.bs.toast', () => {
        toastEl.remove();
    });
}

// =============================================================================
// Loading Overlay
// =============================================================================

function showLoading(message = 'Loading...') {
    let overlay = document.querySelector('.loading-overlay');
    if (!overlay) {
        overlay = document.createElement('div');
        overlay.className = 'loading-overlay';
        overlay.innerHTML = `
            <div class="text-center text-white">
                <div class="spinner-border mb-3" role="status"></div>
                <div class="loading-message">${message}</div>
            </div>
        `;
        document.body.appendChild(overlay);
    }
}

function hideLoading() {
    const overlay = document.querySelector('.loading-overlay');
    if (overlay) {
        overlay.remove();
    }
}

// =============================================================================
// Service Toggle (DHCP, TFTP)
// =============================================================================

function toggleService(serviceName, switchElement) {
    const isEnabled = switchElement.checked;
    const action = isEnabled ? 'start' : 'stop';

    if (!confirm(`Are you sure you want to ${action.toUpperCase()} the ${serviceName} server?`)) {
        switchElement.checked = !isEnabled;
        return;
    }

    switchElement.disabled = true;
    showLoading(`${action === 'start' ? 'Starting' : 'Stopping'} ${serviceName}...`);

    fetch(`/admin/${serviceName.toLowerCase()}/toggle`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ enable: isEnabled })
    })
    .then(response => response.json())
    .then(data => {
        hideLoading();
        if (data.success) {
            updateServiceStatus(serviceName, isEnabled);
            showToast(data.message, 'success');
        } else {
            switchElement.checked = !isEnabled;
            showToast(`Error: ${data.error}`, 'error');
        }
    })
    .catch(error => {
        hideLoading();
        switchElement.checked = !isEnabled;
        showToast(`Error: ${error}`, 'error');
    })
    .finally(() => {
        switchElement.disabled = false;
    });
}

function updateServiceStatus(serviceName, isActive) {
    const statusIndicator = document.querySelector(`[data-service="${serviceName}"] .status-indicator`);
    const statusText = document.querySelector(`[data-service="${serviceName}"] .status-text`);

    if (statusIndicator) {
        statusIndicator.classList.toggle('active', isActive);
        statusIndicator.classList.toggle('inactive', !isActive);
    }

    if (statusText) {
        statusText.textContent = isActive ? 'Active' : 'Inactive';
    }
}

// =============================================================================
// NGINX Restart
// =============================================================================

function restartNGINX(button) {
    if (!confirm('Restart NGINX server?\n\nNote: The page may reload and reconnect automatically.')) {
        return;
    }

    button.disabled = true;
    const originalHTML = button.innerHTML;
    button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Restarting...';

    fetch('/admin/nginx/restart', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showToast('NGINX restarted successfully!', 'success');
            setTimeout(() => location.reload(), 1500);
        } else {
            showToast(`Error: ${data.error}`, 'error');
            button.disabled = false;
            button.innerHTML = originalHTML;
        }
    })
    .catch(error => {
        // NGINX restart might cause temporary disconnect
        showToast('NGINX restarting... Page will reload.', 'info');
        setTimeout(() => location.reload(), 2500);
    });
}

// =============================================================================
// Menu Regeneration
// =============================================================================

function regenerateMenus() {
    if (!confirm('Regenerate iPXE menus from images.yaml?')) return;

    showLoading('Regenerating menus...');

    fetch('/admin/api/menus/regenerate', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    })
        .then(response => {
            if (!response.ok) {
                return response.text().then(text => {
                    throw new Error(`HTTP ${response.status}: ${text}`);
                });
            }
            return response.json();
        })
        .then(data => {
            hideLoading();
            if (data.success) {
                showToast('Menus regenerated successfully!', 'success');
                setTimeout(() => location.reload(), 1000);
            } else {
                console.error('Menu regeneration error:', data.error);
                showToast('Error: ' + (data.error || 'Unknown error'), 'error');
            }
        })
        .catch(error => {
            hideLoading();
            console.error('Fetch error:', error);
            showToast('Error: ' + error.message, 'error');
        });
}

// =============================================================================
// Charts
// =============================================================================

function createDiskUsageChart(canvasId, usedGB, totalGB) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Used', 'Free'],
            datasets: [{
                data: [usedGB, totalGB - usedGB],
                backgroundColor: ['#206bc4', '#e9ecef'],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom'
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.label + ': ' + context.parsed + ' GB';
                        }
                    }
                }
            }
        }
    });
}

function createServiceStatusChart(canvasId, services) {
    const ctx = document.getElementById(canvasId);
    if (!ctx) return;

    const labels = Object.keys(services);
    const data = Object.values(services).map(status => status ? 1 : 0);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Status',
                data: data,
                backgroundColor: data.map(val => val ? '#2fb344' : '#d63939'),
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 1,
                    ticks: {
                        callback: function(value) {
                            return value === 1 ? 'Active' : 'Inactive';
                        }
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
}

// =============================================================================
// Page Fade-In Animation
// =============================================================================

function initPageAnimations() {
    const cards = document.querySelectorAll('.card');
    cards.forEach((card, index) => {
        card.classList.add('fade-in');
        card.style.animationDelay = `${index * 0.05}s`;
    });
}

// =============================================================================
// Initialize on DOM Ready
// =============================================================================

document.addEventListener('DOMContentLoaded', function() {
    initDarkMode();
    initPageAnimations();

    console.log('Kapadokya NetBoot v3.0 - Tabler Edition');
});
