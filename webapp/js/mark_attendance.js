// 1. SELECT ALL LOGIC
function toggleAllAttendance(master) {
  const checkboxes = document.querySelectorAll('.attendance-check');
  checkboxes.forEach(cb => {
    cb.checked = master.checked;
    const row = cb.closest('.attendance-row');
    if (cb.checked) row.classList.add('row-present');
    else row.classList.remove('row-present');
  });
}

// 2. KEYBOARD NAVIGATION LOGIC
document.addEventListener('keydown', function (e) {
  const rows = Array.from(document.querySelectorAll('.attendance-row'));
  let activeRow = document.querySelector('.kb-active');
  let index = rows.indexOf(activeRow);

  if (e.key === 'ArrowDown') {
    e.preventDefault();
    if (index < rows.length - 1) {
      if (activeRow) activeRow.classList.remove('kb-active');
      rows[index + 1].classList.add('kb-active');
      rows[index + 1].scrollIntoView({ block: 'center', behavior: 'smooth' });
    }
  } else if (e.key === 'ArrowUp') {
    e.preventDefault();
    if (index > 0) {
      if (activeRow) activeRow.classList.remove('kb-active');
      rows[index - 1].classList.add('kb-active');
      rows[index - 1].scrollIntoView({ block: 'center', behavior: 'smooth' });
    }
  } else if (e.key === ' ') {
    // Spacebar to toggle
    e.preventDefault();
    if (activeRow) {
      const cb = activeRow.querySelector('.attendance-check');
      cb.checked = !cb.checked;
      if (cb.checked) activeRow.classList.add('row-present');
      else activeRow.classList.remove('row-present');
    }
  } else if (e.key === 'Enter') {
    // Enter to trigger submit
    const form = document.getElementById('attendanceForm');
    if (form && confirm('Process payments for all selected students?')) {
      form.submit();
    }
  }
});

// Initialize highlight on the first row when page loads
window.onload = () => {
  const firstRow = document.querySelector('.attendance-row');
  if (firstRow) firstRow.classList.add('kb-active');

  // Maintain any teacher-dashboard alert removal behavior if both pages coexist
  try {
    const url = new URL(window.location);
    if (url.searchParams.has('success')) {
      alert('Action Processed Successfully!');
      url.searchParams.delete('success');
      window.history.pushState({}, '', url);
    }
  } catch (e) {}
};

// Add click-to-focus for mouse users
document.querySelectorAll('.attendance-row').forEach(row => {
  row.addEventListener('click', function (e) {
    if (e.target.type !== 'checkbox') {
      document.querySelector('.kb-active')?.classList.remove('kb-active');
      this.classList.add('kb-active');
    }
  });
});
