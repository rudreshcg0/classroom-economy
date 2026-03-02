document.addEventListener('DOMContentLoaded', () => {
    const tabs = document.querySelectorAll('.btn-tab');
    const panels = document.querySelectorAll('.action-panel');

    function switchPanel(targetId) {
        // Update Buttons
        tabs.forEach(btn => {
            if (btn.getAttribute('data-target') === targetId) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });

        // Update Panels
        panels.forEach(panel => {
            if (panel.id === targetId) {
                panel.classList.remove('hidden');
            } else {
                panel.classList.add('hidden');
            }
        });

        // Persist selection in URL without reload
        const url = new URL(window.location);
        url.searchParams.set('activeTab', targetId);
        window.history.replaceState({}, '', url);
    }

    // Attach click events
    tabs.forEach(btn => {
        btn.addEventListener('click', () => {
            const target = btn.getAttribute('data-target');
            switchPanel(target);
        });
    });

    // Initialize the active tab: JSP-provided, URL param, or default
    const params = new URLSearchParams(window.location.search);
    const initial = (window.ACTIVE_TAB_ID && String(window.ACTIVE_TAB_ID)) || params.get('activeTab') || 'panel-register';
    switchPanel(initial);
});

function filterTable(input, tableId) {
    const q = input.value.toLowerCase();
    const rows = document.querySelectorAll('#' + tableId + ' tr');
    rows.forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}

function unlinkTeacher(classId) {
    if (confirm('Unlink this teacher from the class?')) {
        document.getElementById('unlinkClassId').value = classId;
        document.getElementById('unlinkForm').submit();
    }
}