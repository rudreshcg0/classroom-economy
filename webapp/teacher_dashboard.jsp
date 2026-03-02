<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES Admin</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/teacher_dashboard.css">
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin-bottom: 20px;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    
    <nav>
        <button onclick="showTab('overview', this)" class="sidebar-link active">🏠 Dashboard Overview</button>
        <button onclick="showTab('attendance', this)" class="sidebar-link">📝 Mark Attendance</button>
        <button onclick="showTab('marketplace', this)" class="sidebar-link">🏪 Marketplace Manager</button>
        
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link">💰 Financial Ledger</a>
        
        <a href="login.jsp" class="sidebar-link logout">🚪 Logout</a>
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
            <p>You have <strong>${marketplaceOrders != null ? marketplaceOrders.size() : 0}</strong> pending purchase requests.</p>
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
            <button class="toggle-btn" id="teacherAuditBtn" onclick="toggleTeacherAudit()">📜 View Transaction History</button>
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

<script src="${pageContext.request.contextPath}/js/teacher_dashboard.js"></script>
</body>
</html>