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

    fetch('teacherAction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    })
    .then(res => res.json())
    .then(data => {
        if (data.status === 'success') {
            loadTeacherBlocks(); // Reload the block list dynamically
            document.getElementById('newRewardName').value = '';
            document.getElementById('newRewardAmount').value = '';
            document.getElementById('newRewardIcon').value = '';
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

    fetch('teacherAction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    })
    .then(res => res.json())
    .then(data => {
        if (data.status === 'success') {
            loadTeacherBlocks(); // Reload the block list dynamically
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(err => console.error('Delete Block Error:', err));
}

function loadTeacherBlocks() {
    fetch('teacherAction?action=getTeacherBlocks')
    .then(res => res.json())
    .then(data => {
        let html = '';
        data.forEach(block => {
            html += `<div class="reward-item" style="display:flex; justify-content:space-between; align-items:center; padding:10px; border:1px solid #f1f5f9; border-radius:8px; margin-bottom:8px;">
                <span><strong>${block.name}</strong> (${block.amount})</span>
                <button class="btn-delete" style="background:#ef4444; color:white; border:none; padding:5px 10px; border-radius:6px; cursor:pointer;" onclick="deleteRewardType(${block.id})">Delete</button>
            </div>`;
        });
        document.getElementById('rewardBlockList').innerHTML = html;
    })
    .catch(err => console.error('Load Blocks Error:', err));
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

    // Toast/Alert Logic (Enhanced for Attendance)
    if (urlParams.has('success')) {
        const count = urlParams.get('count');
        
        // If 'count' exists, it's an Attendance response
        if (count !== null) {
            const num = parseInt(count);
            if (num === 0) {
                alert('Attendance recorded, but no new payments were processed (students were already marked today).');
            } else {
                alert(`Successfully processed attendance and paid ${num} student(s)!`);
            }
        } else {
            // Standard success message for Rewards, Marketplace, etc.
            alert('Action Processed Successfully!');
        }
        
        cleanUrl(['success', 'count', 'error']);
    } 
    else if (urlParams.has('error')) {
        const err = urlParams.get('error');
        if (err === 'insufficient_budget') alert('Error: Insufficient Class Reward Budget!');
        else if (err === 'already_paid_today') alert('Notice: Selected students have already been paid for today.');
        else if (err === 'no_selection') alert('Please select at least one student.');
        else alert('An error occurred. Please try again.');
        
        cleanUrl(['error']);
    }

    // Tab Persistence
    const tabId = urlParams.get('tab') || 'overview';
    const btn = document.querySelector(`[onclick*="${tabId}"]`);
    if(btn) showTab(tabId, btn);

    // Initialize marketplace section if on marketplace tab
    if (tabId === 'marketplace') {
        showMarketplaceSection('create');
    }

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
        if (event.target && event.target.classList.contains('modal-overlay')) {
            event.target.style.display = 'none';
        }
    };

    if (typeof initStudentGridKeyboardNav === "function") {
        initStudentGridKeyboardNav();
    }
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

/* * FINANCE & LIMIT SYSTEM LOGIC
 * Add these to your teacher_dashboard.js
 */

// Handle cleaning URL parameters and showing specialized alerts
const originalCleanUrl = cleanUrl;
cleanUrl = function(params) {
    const urlParams = new URLSearchParams(window.location.search);
    
    if (urlParams.has('success')) {
        const val = urlParams.get('success');
        if (val === 'request_sent') {
            alert('✅ Extension request sent successfully! Please wait for Admin approval.');
        }
    }
    
    if (urlParams.has('error')) {
        const err = urlParams.get('error');
        if (err === 'limit_exceeded') {
            alert('⚠️ Transaction Failed: You have reached your daily reward limit. Please request an extension.');
        }
    }

    // Call the original cleanUrl logic provided in your base code
    originalCleanUrl(params);
};

// Close modals when clicking the 'Done' or 'Close' buttons
function closeExtensionModal() {
    document.getElementById('extensionModal').style.display = 'none';
}

/**
 * Re-initializing the reward grid logic to ensure it 
 * references the correct container in the updated JSP
 */
function openRewardGrid(type) {
    const selected = document.querySelectorAll('.student-reward-card input:checked');
    if (selected.length === 0) {
        alert("Please select at least one student!");
        return;
    }

    const modal = document.getElementById('rewardGridModal');
    const container = document.getElementById('rewardGridContainer'); // Updated ID match
    const title = document.getElementById('gridModalTitle'); // Updated ID match

    title.textContent = type === 'award' ? 'Select Reward Block' : 'Select Deduction Block';
    container.innerHTML = '<div style="grid-column: span 3; text-align:center;">Loading rewards...</div>';

    fetch(`rewardAction?action=getTeacherRewards&type=${type}`)
        .then(response => response.json())
        .then(data => {
            container.innerHTML = ''; 
            if (data.rewards && data.rewards.length > 0) {
                data.rewards.forEach(rt => {
                    const block = document.createElement('div');
                    block.className = 'card reward-block';
                    block.style.textAlign = 'center';
                    block.style.cursor = 'pointer';
                    block.onclick = () => submitReward(rt.id);
                    block.innerHTML = `
                        <div style="font-size: 32px; margin-bottom:10px;">${rt.icon}</div>
                        <div style="font-weight: bold; font-size:14px;">${rt.name}</div>
                        <div style="color: ${type === 'award' ? '#10b981' : '#ef4444'}; font-weight:bold;">
                            ${type === 'award' ? '+' : '-'}₹${Math.abs(rt.amount)}
                        </div>
                    `;
                    container.appendChild(block);
                });
            } else {
                container.innerHTML = `<p style="grid-column: span 3; color: #64748b; text-align:center;">No ${type} blocks found.</p>`;
            }
            modal.style.display = 'flex';
        });
}

function showMarketplaceSection(sectionId) {
    // Hide all marketplace sections
    document.querySelectorAll('.marketplace-section').forEach(section => {
        section.style.display = 'none';
    });
    
    // Show selected section
    const selectedSection = document.getElementById('marketplace-' + sectionId);
    if (selectedSection) {
        selectedSection.style.display = 'block';
        
        // If viewing listings, load the data
        if (sectionId === 'listings') {
            loadTeacherListings();
        }
    }
}

function loadTeacherListings() {
    console.log('DEBUG: loadTeacherListings called');
    fetch('teacherAction?action=viewTeacherMarketplaceItems')
        .then(response => {
            console.log('DEBUG: Response received', response);
            return response.json();
        })
        .then(data => {
            console.log('DEBUG: Data received', data);
            const container = document.getElementById('listingsContainer');
            container.innerHTML = '';
            
            if (data.items && data.items.length > 0) {
                console.log('DEBUG: Processing ' + data.items.length + ' items');
                const table = document.createElement('table');
                table.style.width = '100%';
                table.style.borderCollapse = 'collapse';
                table.innerHTML = `
                    <thead>
                        <tr style="background: #f7fafc;">
                            <th style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left;">Item Name</th>
                            <th style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left;">Description</th>
                            <th style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left;">Price</th>
                            <th style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left;">Stock</th>
                            <th style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9; text-align: left;">Actions</th>
                        </tr>
                    </thead>
                    <tbody></tbody>
                `;
                
                const tbody = table.querySelector('tbody');
                data.items.forEach(item => {
                    console.log('DEBUG: Processing item', item);
                    const row = document.createElement('tr');
                    row.innerHTML = `
                        <td style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9;">${item.item_name}</td>
                        <td style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9;">${item.item_description || ''}</td>
                        <td style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9;">$${item.price}</td>
                        <td style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9;">${item.stock === -1 ? '∞' : item.stock}</td>
                        <td style="padding: 14px 16px; border-bottom: 1px solid #f1f5f9;">
                            <button onclick="deleteMarketplaceItem(${item.item_id})" class="btn-submit" style="background:#ef4444; padding: 6px 12px; font-size: 12px;">Delete</button>
                        </td>
                    `;
                    tbody.appendChild(row);
                });
                
                container.appendChild(table);
            } else {
                console.log('DEBUG: No items found');
                container.innerHTML = '<p style="text-align: center; color: #94a3b8; padding: 20px;">No items listed yet.</p>';
            }
        })
        .catch(err => {
            console.error('Error loading listings:', err);
            document.getElementById('listingsContainer').innerHTML = '<p style="text-align: center; color: #ef4444;">Error loading listings.</p>';
        });
}

function deleteMarketplaceItem(itemId) {
    if (!confirm('Are you sure you want to delete this item? This action cannot be undone.')) {
        return;
    }
    
    const params = new URLSearchParams();
    params.append('action', 'deleteMarketplaceItem');
    params.append('itemId', itemId);
    
    fetch('teacherAction', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: params
    })
    .then(response => response.json())
    .then(data => {
        if (data.status === 'success') {
            loadTeacherListings(); // Reload the listings
        } else {
            alert('Error: ' + data.message);
        }
    })
    .catch(err => {
        console.error('Delete error:', err);
        alert('Error deleting item.');
    });
}