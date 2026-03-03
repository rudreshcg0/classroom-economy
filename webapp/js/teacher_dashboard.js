/**
 * TEACHER DASHBOARD CORE LOGIC
 * Handles: Tab switching, Reward System, Marketplace Management, and UI States
 */

// 1. Tab Navigation System
function showTab(tabId, element) {
    // Switch Panels
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    const panel = document.getElementById(tabId);
    if (panel) panel.classList.add('active');

    // Update Sidebar Active State
    document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
    if (element) element.classList.add('active');

    // Persistence: Update URL without reloading
    const url = new URL(window.location);
    url.searchParams.set('tab', tabId);
    window.history.pushState({}, '', url);
}

// 2. Reward System: Student Card Selection
function toggleStudentSelection(card) {
    const checkbox = card.querySelector('input[type="checkbox"]');
    checkbox.checked = !checkbox.checked;
    
    if (checkbox.checked) {
        card.style.borderColor = '#8b5cf6'; // Purple highlight
        card.style.background = '#f5f3ff';
        card.style.boxShadow = '0 0 0 2px rgba(139, 92, 246, 0.2)';
    } else {
        card.style.borderColor = '#f1f5f9';
        card.style.background = 'white';
        card.style.boxShadow = 'none';
    }
}

// 3. Reward System: Select/Deselect All Students
function toggleAllRewardStudents(master) {
    document.querySelectorAll('.student-reward-card').forEach(card => {
        const checkbox = card.querySelector('input[type="checkbox"]');
        checkbox.checked = master.checked;
        
        if (master.checked) {
            card.style.borderColor = '#8b5cf6';
            card.style.background = '#f5f3ff';
        } else {
            card.style.borderColor = '#f1f5f9';
            card.style.background = 'white';
        }
    });
}

// 4. Reward System: Instant Search/Filter
function filterRewardStudents() {
    const q = document.getElementById('studentRewardSearch').value.toLowerCase();
    document.querySelectorAll('.student-reward-card').forEach(card => {
        const nameMatch = card.dataset.name.includes(q);
        const rollMatch = card.dataset.roll.includes(q);
        card.style.display = (nameMatch || rollMatch) ? 'block' : 'none';
    });
}

// 5. Reward System: Modal Logic & Submissions
function openRewardGrid(type) {
    const selected = document.querySelectorAll('.student-reward-card input:checked');
    if (selected.length === 0) {
        alert("Please select at least one student!");
        return;
    }

    const modal = document.getElementById('rewardGridModal');
    const title = modal.querySelector('h2');
    title.textContent = type === 'award' ? 'Select Reward Block' : 'Select Deduction Block';

    // Fetch filtered blocks (positive for awards, negative for deductions)
    fetch(`rewardAction?action=getTeacherRewards&type=${type}`)
        .then(response => response.json())
        .then(data => {
            const grid = modal.querySelector('[style*="grid-template-columns"]');
            grid.innerHTML = ''; 
            if (data.rewards && data.rewards.length > 0) {
                data.rewards.forEach(rt => {
                    const block = document.createElement('div');
                    block.className = 'reward-block';
                    block.onclick = () => submitReward(rt.id);
                    block.innerHTML = `
                        <div style="font-size: 32px;">${rt.icon}</div>
                        <div style="font-weight: bold;">${rt.name}</div>
                        <div style="color: ${rt.isPositive ? '#10b981' : '#ef4444'};">
                            ${rt.isPositive ? '+' : ''}${rt.amount}
                        </div>
                    `;
                    grid.appendChild(block);
                });
            } else {
                grid.innerHTML = `<p style="grid-column: span 3; color: #64748b;">No ${type} blocks found.</p>`;
            }
            modal.style.display = 'flex';
        })
        .catch(err => console.error('Error:', err));
}

function submitReward(rewardId) {
    const form = document.getElementById('rewardSubmitForm');
    if (!form) return;

    document.getElementById('finalRewardId').value = rewardId;

    // Clear old hidden inputs
    form.querySelectorAll('.temp-input').forEach(i => i.remove());
    
    // Add selected student IDs
    document.querySelectorAll('.student-reward-card input:checked').forEach(cb => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'selectedStudents';
        input.value = cb.value;
        input.className = 'temp-input';
        form.appendChild(input);
    });

    form.submit(); // Submit via standard form for page redirection
}

// 6. Reward Block Management (Add/Delete)
function addRewardType(event) {
    event.preventDefault();
    const name = document.getElementById('newRewardName').value;
    const amount = document.getElementById('newRewardAmount').value;
    const icon = document.getElementById('newRewardIcon').value;

    const params = new URLSearchParams();
    params.append('action', 'addRewardType');
    params.append('name', name);
    params.append('amount', amount);
    params.append('icon', icon);

    fetch('rewardAction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    })
    .then(res => res.json())
    .then(data => {
        if (data.status === 'success') {
            location.reload(); // Refresh to update both management list and reward grid
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(err => console.error('Add Block Error:', err));
}

function deleteRewardType(rewardId) {
    if (!confirm('Are you sure you want to delete this reward block?')) return;

    const params = new URLSearchParams();
    params.append('action', 'deleteRewardType');
    params.append('rewardId', rewardId);

    fetch('rewardAction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    })
    .then(res => res.json())
    .then(data => {
        if (data.status === 'success') {
            const item = document.getElementById(`reward-item-${rewardId}`);
            if (item) item.remove();
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(err => console.error('Delete Block Error:', err));
}

// 7. Marketplace: UI Toggles
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

// 8. Lifecycle & Initialization
window.onload = function () {
    const urlParams = new URLSearchParams(window.location.search);

    // Toast/Alert Logic
    if (urlParams.has('success')) {
        alert('Action Processed Successfully!');
        cleanUrl(['success', 'error']);
    } else if (urlParams.has('error')) {
        const err = urlParams.get('error');
        if(err === 'insufficient_budget') alert('Error: Insufficient Class Reward Budget!');
        else alert('An error occurred. Please try again.');
        cleanUrl(['error']);
    }

    // Tab Persistence
    const tabId = urlParams.get('tab') || 'overview';
    const btn = document.querySelector(`[onclick*="${tabId}"]`);
    if(btn) showTab(tabId, btn);

    // Attendance Launcher
    const classSelect = document.getElementById('attendanceClassSelect');
    const launchBtn = document.getElementById('launchAttendanceBtn');
    if (classSelect && launchBtn) {
        const handler = () => { launchBtn.disabled = classSelect.value === ''; };
        classSelect.addEventListener('change', handler);
        handler(); 
    }

    // Click outside modal to close
    window.onclick = function(event) {
        if (event.target.classList.contains('modal-overlay')) {
            event.target.style.display = 'none';
        }
    };

    initStudentGridKeyboardNav();
};

function cleanUrl(params) {
    const url = new URL(window.location);
    params.forEach(p => url.searchParams.delete(p));
    window.history.pushState({}, '', url);
}

function filterAuditTable() {
    let filter = document.getElementById('auditSearchInput').value.toLowerCase();
    let rows = document.getElementsByClassName('audit-row');
    for (let row of rows) {
        let student = row.querySelector('.search-student').textContent.toLowerCase();
        let item = row.querySelector('.search-item').textContent.toLowerCase();
        row.style.display = (student.includes(filter) || item.includes(filter)) ? '' : 'none';
    }
}

/**
 * ============================================
 * REWARD SYSTEM KEYBOARD NAVIGATION
 * ============================================
 */
function initStudentGridKeyboardNav() {
    const grid = document.getElementById('studentGrid');
    if (!grid) return;

    const cards = Array.from(grid.querySelectorAll('.student-reward-card'));
    if (cards.length === 0) return;

    let focusedIndex = -1;

    grid.addEventListener('keydown', (e) => {
        if (e.target.tagName === 'INPUT') return;
        
        const numColumns = getComputedStyle(grid).gridTemplateColumns.split(' ').length;
        let newIndex = focusedIndex;

        if (focusedIndex === -1 && ['ArrowRight', 'ArrowLeft', 'ArrowDown', 'ArrowUp'].includes(e.key)) {
            e.preventDefault();
            newIndex = 0;
        } else {
            switch (e.key) {
                case 'ArrowRight':
                    e.preventDefault();
                    newIndex = Math.min(focusedIndex + 1, cards.length - 1);
                    break;
                case 'ArrowLeft':
                    e.preventDefault();
                    newIndex = Math.max(focusedIndex - 1, 0);
                    break;
                case 'ArrowDown':
                    e.preventDefault();
                    newIndex = Math.min(focusedIndex + numColumns, cards.length - 1);
                    break;
                case 'ArrowUp':
                    e.preventDefault();
                    newIndex = Math.max(focusedIndex - numColumns, 0);
                    break;
                case ' ': 
                    e.preventDefault();
                    if(focusedIndex !== -1) toggleStudentSelection(cards[focusedIndex]);
                    return;
                default:
                    return;
            }
        }

        if (newIndex !== focusedIndex) {
            if(focusedIndex !== -1) cards[focusedIndex].classList.remove('focused');
            cards[newIndex].classList.add('focused');
            cards[newIndex].focus();
            focusedIndex = newIndex;
        }
    });
}