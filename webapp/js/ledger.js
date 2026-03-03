/* Location: webapp/js/ledger.js */

/**
 * Filter student list based on name or roll number
 */
function filterStudents() {
    const query = document.getElementById('studentSearch').value.toLowerCase();
    const rows = document.querySelectorAll('.student-row');
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(query) ? '' : 'none';
    });
}

/**
 * Filter transaction ledger entries
 */
function filterTransactions() {
    const query = document.getElementById('txSearch').value.toLowerCase();
    const rows = document.querySelectorAll('.tx-row');
    
    rows.forEach(row => {
        const text = row.textContent.toLowerCase();
        row.style.display = text.includes(query) ? '' : 'none';
    });
}

// Initialize tooltips or logs if needed
document.addEventListener('DOMContentLoaded', () => {
    console.log("VCES Ledger System Initialized");
});