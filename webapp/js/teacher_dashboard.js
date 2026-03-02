function showTab(tabId, element) {
    // 1. Switch Panels
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    const panel = document.getElementById(tabId);
    if (panel) panel.classList.add('active');

    // 2. Clear all active states in sidebar
    document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
    
    // 3. Set current active state
    if (element) element.classList.add('active');
}

function toggleTeacherAudit() {
    const mgmt = document.getElementById('teacherMarketManagement');
    const audit = document.getElementById('teacherMarketAudit');
    const btn = document.getElementById('teacherAuditBtn');
    if (mgmt.style.display === 'none') {
        mgmt.style.display = 'block';
        audit.style.display = 'none';
        btn.innerText = '📜 View Transaction History';
    } else {
        mgmt.style.display = 'none';
        audit.style.display = 'block';
        btn.innerText = '🏪 Back to Management';
    }
}

function toggleChecks(source) {
    document.getElementsByName('selectedOrders').forEach(c => (c.checked = source.checked));
}

function filterAuditTable() {
    let filter = document.getElementById('auditSearchInput').value.toLowerCase();
    let rows = document.getElementsByClassName('audit-row');
    for (let row of rows) {
        let student = row.querySelector('.search-student').textContent.toLowerCase();
        let item = row.querySelector('.search-item').textContent.toLowerCase();
        row.style.display = student.includes(filter) || item.includes(filter) ? '' : 'none';
    }
}

window.onload = function () {
    // Handle success alerts
    if (new URLSearchParams(window.location.search).has('success')) {
        alert('Action Processed Successfully!');
        const url = new URL(window.location);
        url.searchParams.delete('success');
        window.history.pushState({}, '', url);
    }
    
    // Logic to keep correct tab open if page reloads via Servlet forward
    const params = new URLSearchParams(window.location.search);
    if (params.has('tab')) {
        const tabId = params.get('tab');
        const btn = document.querySelector(`[onclick*="${tabId}"]`);
        if(btn) showTab(tabId, btn);
    }

    // Attendance: enable launch button when a class is selected
    const classSelect = document.getElementById('attendanceClassSelect');
    const launchBtn = document.getElementById('launchAttendanceBtn');
    if (classSelect && launchBtn) {
        const handler = () => { launchBtn.disabled = classSelect.value === ''; };
        classSelect.addEventListener('change', handler);
        handler();
    }
};