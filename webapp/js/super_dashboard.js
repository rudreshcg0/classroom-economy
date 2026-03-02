document.addEventListener('DOMContentLoaded', () => {
    const tabs = document.querySelectorAll('.tab-btn');
    const sections = document.querySelectorAll('.tab-content');

    tabs.forEach(btn => {
        btn.addEventListener('click', () => {
            // Remove active from all buttons
            tabs.forEach(t => t.classList.remove('active'));
            // Hide all sections
            sections.forEach(s => s.classList.remove('active'));

            // Add active to current
            btn.classList.add('active');
            const target = btn.getAttribute('data-target');
            document.getElementById(target).classList.add('active');
        });
    });
});

function editSchool(id, currentName) {
    const newName = prompt('Enter new name for ' + currentName + ':', currentName);
    if (newName && newName !== currentName) {
        document.getElementById('editSchoolId').value = id;
        document.getElementById('editNewName').value = newName;
        document.getElementById('editForm').submit();
    }
}

function filterTable() {
    const filter = document.getElementById('schoolSearch').value.toUpperCase();
    const rows = document.querySelector('#schoolTable tbody').getElementsByTagName('tr');
    for (let i = 0; i < rows.length; i++) {
        const text = rows[i].innerText.toUpperCase();
        rows[i].style.display = text.indexOf(filter) > -1 ? '' : 'none';
    }
}