<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User, models.MarketplaceItem" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES Admin</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background-color: #f0f2f5; display: flex; }
        .sidebar { width: 260px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; }
        .sidebar h2 { color: #63b3ed; margin-bottom: 30px; }
        .sidebar-link { display: block; color: #cbd5e0; text-decoration: none; padding: 12px; border-radius: 8px; margin-bottom: 10px; transition: 0.3s; cursor: pointer; }
        .sidebar-link:hover { background: #2d3748; color: white; }
        .sidebar-link.active { background: #3182ce; color: white; }
        .main-content { margin-left: 310px; padding: 40px; width: calc(100% - 310px); }
        .tab-panel { display: none; } .tab-panel.active { display: block; }
        .card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .balance-box { background: #ebf8ff; color: #2b6cb0; padding: 20px; border-radius: 10px; border-left: 5px solid #3182ce; margin-bottom: 25px; }
        .btn-submit { background-color: #38a169; color: white; padding: 12px; border: none; border-radius: 8px; cursor: pointer; font-weight: bold; transition: 0.2s; }
        .btn-submit:hover { opacity: 0.9; }
        input, select { padding: 12px; width: 100%; margin-bottom: 15px; border-radius: 8px; border: 1px solid #cbd5e0; box-sizing: border-box; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; text-align: left;}
        th, td { padding: 12px; border-bottom: 1px solid #edf2f7; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .bg-active { background: #c6f6d5; color: #22543d; }
        .bg-low { background: #feebc8; color: #744210; }
        .bg-out { background: #fed7d7; color: #822727; }
        .search-container { position: relative; margin-bottom: 20px; }
        .search-container input { padding-left: 40px; border: 2px solid #e2e8f0; }
        .search-icon { position: absolute; left: 15px; top: 12px; color: #a0aec0; }
        .toggle-btn { background: #4a5568; margin-bottom: 20px; width: auto; padding: 8px 16px; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
    <nav>
        <div onclick="showTab('overview', this)" class="sidebar-link active">🏠 Dashboard Overview</div>
        <div onclick="showTab('attendance', this)" class="sidebar-link">📝 Mark Attendance</div>
        <div onclick="showTab('marketplace', this)" class="sidebar-link">🏪 Marketplace Manager</div>
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link">💰 Financial Ledger</a>
        <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
        <a href="login.html" style="color: #fc8181;" class="sidebar-link">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    <div id="overview" class="tab-panel active">
        <h1>Teacher Dashboard</h1>
        <div class="balance-box">
            <small>CLASS REWARD BUDGET</small>
            <h2 style="margin: 5px 0;">$${allowance != null ? allowance : "0.00"}</h2>
        </div>
        <div class="card">
            <h3>Quick Summary</h3>
            <p>You have <strong>${marketplaceOrders.size()}</strong> pending purchase requests.</p>
        </div>
    </div>

    <div id="attendance" class="tab-panel">
        <h1>Attendance Console</h1>
        <div class="card">
            <h3>📝 Process Session Salaries</h3>
            <form action="markAttendance" method="GET">
                <select name="classId" required>
                    <option value="">-- Choose Class --</option>
                    <% List<Map<String, Object>> cls = (List<Map<String, Object>>) request.getAttribute("classes");
                       if (cls != null) for (Map<String, Object> c : cls) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                    <% } %>
                </select>
                <button type="submit" class="btn-submit" style="width: 100%;">Launch Attendance Console</button>
            </form>
        </div>
    </div>

    <div id="marketplace" class="tab-panel">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h1>Marketplace Manager</h1>
            <button class="btn-submit toggle-btn" id="teacherAuditBtn" onclick="toggleTeacherAudit()">📜 View Transaction History</button>
        </div>
        
        <div id="teacherMarketManagement">
            <div class="card">
                <h3>🚀 Create New Item</h3>
                <form action="teacherAction" method="POST" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
                    <input type="hidden" name="action" value="createItem">
                    <input type="text" name="itemName" placeholder="Item Name" required>
                    <input type="number" name="price" placeholder="Price" step="0.01" required>
                    <input type="number" name="stock" placeholder="Stock (-1 for ∞)" required>
                    <input type="text" name="description" placeholder="Short Description">
                    <button type="submit" class="btn-submit" style="grid-column: span 2; background: #3182ce;">Add to Store</button>
                </form>
            </div>

            <div class="card" style="border-top: 4px solid #38a169;">
                <h3>🛒 Pending Requests</h3>
                <form action="teacherAction" method="POST">
                    <input type="hidden" name="action" value="bulkProcess">
                    <table>
                        <thead>
                            <tr style="background: #f7fafc;">
                                <th><input type="checkbox" onclick="toggleChecks(this)"></th>
                                <th>Student</th><th>Item</th><th>Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% List<Map<String, Object>> mOrders = (List<Map<String, Object>>)request.getAttribute("marketplaceOrders");
                               if(mOrders != null && !mOrders.isEmpty()) { for(Map<String, Object> o : mOrders) { %>
                                <tr>
                                    <td><input type="checkbox" name="selectedOrders" value="<%= o.get("id") %>"></td>
                                    <td><%= o.get("student") %></td>
                                    <td><span style="background:#eef2ff; color:#4338ca; padding:4px 8px; border-radius:4px;"><%= o.get("item") %></span></td>
                                    <td><small><%= o.get("date") %></small></td>
                                </tr>
                            <% } } else { %> <tr><td colspan="4" align="center">No pending requests.</td></tr> <% } %>
                        </tbody>
                    </table>
                    <div style="margin-top:20px; display:flex; gap:15px;">
                        <button type="submit" name="decision" value="APPROVED" class="btn-submit" style="flex:1;">Approve Selected</button>
                        <button type="submit" name="decision" value="REJECTED" class="btn-submit" style="background:#e53e3e; flex:1;">Reject & Refund</button>
                    </div>
                </form>
            </div>
        </div>

        <div id="teacherMarketAudit" style="display: none;">
            <div class="card">
                <h3>📜 Transaction Ledger</h3>
                <div class="search-container">
                    <span class="search-icon">🔍</span>
                    <input type="text" id="auditSearchInput" onkeyup="filterAuditTable()" placeholder="Search by student or item...">
                </div>
                <table>
                    <thead>
                        <tr style="background: #f7fafc;">
                            <th>Student</th><th>Item</th><th>Price</th><th>Date</th><th>Status</th>
                        </tr>
                    </thead>
                    <tbody id="auditTableBody">
                        <% List<Map<String, Object>> audit = (List<Map<String, Object>>)request.getAttribute("fullAudit");
                           if(audit != null) { for(Map<String, Object> a : audit) { %>
                            <tr class="audit-row">
                                <td class="search-student"><strong><%= a.get("student") %></strong></td>
                                <td class="search-item"><%= a.get("item") %></td>
                                <td>$<%= a.get("price") %></td>
                                <td><small><%= a.get("date") %></small></td>
                                <td><span class="badge <%= a.get("status").equals("COMPLETED") ? "bg-active" : "bg-out" %>"><%= a.get("status") %></span></td>
                            </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
    function showTab(tabId, element) {
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        document.querySelectorAll('.sidebar-link').forEach(l => l.classList.remove('active'));
        document.getElementById(tabId).classList.add('active');
        element.classList.add('active');
    }

    function toggleTeacherAudit() {
        const mgmt = document.getElementById('teacherMarketManagement');
        const audit = document.getElementById('teacherMarketAudit');
        const btn = document.getElementById('teacherAuditBtn');
        if (mgmt.style.display === "none") {
            mgmt.style.display = "block"; audit.style.display = "none";
            btn.innerText = "📜 View Transaction History";
        } else {
            mgmt.style.display = "none"; audit.style.display = "block";
            btn.innerText = "🏪 Back to Management";
        }
    }

    function toggleChecks(source) {
        document.getElementsByName('selectedOrders').forEach(c => c.checked = source.checked);
    }

    function filterAuditTable() {
        let filter = document.getElementById("auditSearchInput").value.toLowerCase();
        let rows = document.getElementsByClassName("audit-row");
        for (let row of rows) {
            let student = row.querySelector(".search-student").textContent.toLowerCase();
            let item = row.querySelector(".search-item").textContent.toLowerCase();
            row.style.display = (student.includes(filter) || item.includes(filter)) ? "" : "none";
        }
    }

    window.onload = function() {
        if (new URLSearchParams(window.location.search).has('success')) {
            alert("Action Processed Successfully!");
            const url = new URL(window.location);
            url.searchParams.delete('success');
            window.history.pushState({}, '', url);
        }
    };
</script>
</body>
</html>