document.addEventListener('DOMContentLoaded', () => {
    const tabs = document.querySelectorAll('.btn-tab');
    const panels = document.querySelectorAll('.action-panel');

    // 1. Tab Switching Logic
    function switchPanel(targetId) {
        tabs.forEach(btn => {
            btn.classList.toggle('active', btn.getAttribute('data-target') === targetId);
        });

        panels.forEach(panel => {
            panel.classList.toggle('hidden', panel.id !== targetId);
        });

        // Persist selection in URL
        const url = new URL(window.location);
        url.searchParams.set('activeTab', targetId);
        window.history.replaceState({}, '', url);
    }

    tabs.forEach(btn => {
        btn.addEventListener('click', () => switchPanel(btn.getAttribute('data-target')));
    });

    // Initialize Active Tab
    const params = new URLSearchParams(window.location.search);
    const initial = (window.ACTIVE_TAB_ID && String(window.ACTIVE_TAB_ID)) || params.get('activeTab') || 'panel-register';
    
    // Only switch if we are in the 'management' view (where these panels exist)
    if (panels.length > 0) {
        switchPanel(initial);
    }

    // 2. Finance Success Toasts
    if (params.get('success') === '1' && params.get('view') === 'finance') {
        alert("✅ Financial update processed successfully.");
    }
});

/**
 * RESTORED: Filters Registry tables (Staff/Students)
 */
function filterTable(input, tableId) {
    const q = input.value.toLowerCase();
    const rows = document.querySelectorAll('#' + tableId + ' tr');
    rows.forEach(row => {
        // Skip header rows if any, or search all text
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}

/**
 * Unlink Teacher Logic
 */
function unlinkTeacher(classId) {
    if (confirm('Unlink this teacher from the class?')) {
        document.getElementById('unlinkClassId').value = classId;
        document.getElementById('unlinkForm').submit();
    }
}

/**
 * Finance View Search
 */
function filterFinanceTeachers() {
    const query = document.getElementById('financeSearch').value.toLowerCase();
    const rows = document.querySelectorAll('.finance-teacher-row');
    rows.forEach(row => {
        row.style.display = row.textContent.toLowerCase().includes(query) ? '' : 'none';
    });
}