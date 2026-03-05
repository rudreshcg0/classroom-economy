<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%
    User userObj = (User) session.getAttribute("user");
    if (userObj == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES Admin</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/teacher_dashboard.css">
    <style>
        .limit-box { background: #f8fafc; border-left: 4px solid #6366f1; padding: 15px; border-radius: 8px; margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center; }
        .limit-info h2 { margin: 0; font-size: 28px; color: #1e293b; }
        .limit-info small { color: #64748b; font-weight: bold; text-transform: uppercase; }
        .btn-request { background: #6366f1; color: white; border: none; padding: 10px 18px; border-radius: 8px; font-weight: 600; cursor: pointer; transition: 0.2s; }
        .btn-request:hover { background: #4f46e5; }
        .alert-error { background: #fee2e2; color: #991b1b; padding: 12px; border-radius: 8px; margin-bottom: 20px; border: 1px solid #fecaca; }
    </style>
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

        <% if(request.getParameter("error") != null && request.getParameter("error").equals("limit_exceeded")) { %>
            <div class="alert-error">⚠️ Daily Limit Exceeded. Please request an extension to award more money.</div>
        <% } %>

        <div class="limit-box">
            <div class="limit-info">
                <small>Remaining Daily Soft Limit</small>
                <h2>₹${remainingLimit != null ? String.format("%.2f", remainingLimit) : "0.00"}</h2>
            </div>
            <button class="btn-request" onclick="document.getElementById('extensionModal').style.display='flex'">➕ Request Extension</button>
        </div>

        <div class="card">
            <h3>Quick Summary</h3>
            <p>You have <strong>${marketplaceOrders != null ? marketplaceOrders.size() : 0}</strong> pending purchase requests.</p>
        </div>

        <div class="card" style="border-top: 4px solid #8b5cf6;">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                <h3 style="margin:0;">✨ Reward Console</h3>
                <button class="toggle-btn" style="background:#8b5cf6" onclick="document.getElementById('rewardConfigModal').style.display='flex'">⚙️ Manage Blocks</button>
            </div>

            <form action="rewardAction" method="GET" style="margin-bottom: 20px; display: flex; gap: 10px;">
                <select name="classId" style="margin:0; flex:1;">
                    <option value="">-- Select Class to Reward --</option>
                    <% 
                        List<Map<String, Object>> rewardCls = (List<Map<String, Object>>) request.getAttribute("classes");
                        String selClass = (String) request.getAttribute("selectedRewardClass");
                        if (rewardCls != null) { 
                            for (Map<String, Object> c : rewardCls) { 
                    %>
                        <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(selClass)) ? "selected" : "" %>><%= c.get("name") %></option>
                    <%      } 
                        } 
                    %>
                </select>
                <button type="submit" class="btn-submit" style="background:#6366f1; width:auto;">Load Students</button>
            </form>

            <% 
                List<User> rewardStudents = (List<User>) request.getAttribute("rewardStudents"); 
                if (rewardStudents != null) { 
            %>
                <div class="search-container">
                    <span class="search-icon">🔍</span>
                    <input type="text" id="studentRewardSearch" onkeyup="filterRewardStudents()" placeholder="Search student...">
                </div>

                <div style="margin-bottom: 15px; display: flex; justify-content: space-between; align-items: center;">
                    <label style="cursor:pointer;"><input type="checkbox" onclick="toggleAllRewardStudents(this)"> <strong>Select All</strong></label>
                    <div>
                        <button type="button" class="btn-submit" style="background:#ef4444; width:auto; margin-right: 10px;" onclick="openRewardGrid('deduct')">Deduct Selected</button>
                        <button type="button" class="btn-submit" style="background:#10b981; width:auto;" onclick="openRewardGrid('award')">Award Selected</button>
                    </div>
                </div>

                <div id="studentGrid" class="scroll-area" style="max-height: 400px; display: grid; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); gap: 10px; border:none;">
                    <% for (User s : rewardStudents) { %>
                        <div class="student-reward-card card" tabindex="0" data-name="<%= s.getUsername().toLowerCase() %>" data-roll="<%= s.getRollNo().toLowerCase() %>" style="margin:0; padding:10px; text-align:center; border: 1px solid #e2e8f0; cursor:pointer;" onclick="toggleStudentSelection(this)">
                            <input type="checkbox" name="selectedStudents" value="<%= s.getId() %>" style="display:none;">
                            <div style="font-size: 24px; margin-bottom: 5px;">👤</div>
                            <div style="font-weight: bold; font-size: 13px;"><%= s.getUsername() %></div>
                            <div style="color: #64748b; font-size: 11px;">Roll: <%= s.getRollNo() %></div>
                            <div style="color: #10b981; font-weight: bold; font-size: 12px;">₹<%= s.getBalance() %></div>
                        </div>
                    <% } %>
                </div>
            <% } %>
        </div>
    </div>

    <div id="attendance" class="tab-panel">
        <h1>Attendance Console</h1>
        <div class="card">
            <h3>📝 Process Session Salaries</h3>
            <form action="markAttendance" method="GET" id="attendanceLaunchForm">
                <select name="classId" id="attendanceClassSelect" required>
                    <option value="">-- Choose Class --</option>
                    <% 
                        List<Map<String, Object>> attCls = (List<Map<String, Object>>) request.getAttribute("classes");
                        if (attCls != null && !attCls.isEmpty()) { 
                            for (Map<String, Object> c : attCls) { 
                    %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                    <%      } 
                        } 
                    %>
                </select>
                <button type="submit" id="launchAttendanceBtn" class="btn-submit" style="width: 100%;" disabled>Launch Attendance Console</button>
            </form>
        </div>
    </div>

   <div id="marketplace" class="tab-panel">
    <h1>Marketplace Manager</h1>
    
    <div class="card">
        <h3>🚀 Create New Item</h3>
        <form action="teacherAction" method="POST" style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px;">
            <input type="hidden" name="action" value="createItem">
            <input type="text" name="itemName" placeholder="Item Name" required>
            <input type="number" name="price" placeholder="Price" step="0.01" required>
            <input type="number" name="stock" placeholder="Stock (-1 for ∞)" required>
            <input type="text" name="description" placeholder="Short Description">
            
            <div style="grid-column: span 2; display: flex; align-items: center; gap: 10px; background: #f1f5f9; padding: 10px; border-radius: 8px;">
                <input type="checkbox" name="requiresApproval" id="requiresApproval" checked style="width: auto; margin: 0;">
                <label for="requiresApproval" style="font-size: 14px; color: #475569; font-weight: 600; cursor: pointer;">
                    Requires Manual Teacher Approval to Buy
                </label>
            </div>

            <button type="submit" class="btn-submit" style="grid-column: span 2; background: #3182ce;">Add to Store</button>
        </form>
    </div>

    <div class="card" style="border-top: 4px solid #f59e0b;">
        <h3>📦 Pending Fulfillment Requests</h3>
        <form action="teacherAction" method="POST">
            <input type="hidden" name="action" value="bulkProcess">
            <table style="width: 100%; border-collapse: collapse; margin-top: 15px;">
                <thead>
                    <tr style="text-align: left; border-bottom: 2px solid #e2e8f0;">
                        <th style="padding: 10px;">Select</th>
                        <th>Student</th>
                        <th>Item</th>
                        <th>Date</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                        List<Map<String, Object>> orders = (List<Map<String, Object>>) request.getAttribute("marketplaceOrders");
                        if (orders != null && !orders.isEmpty()) {
                            for (Map<String, Object> o : orders) { 
                    %>
                        <tr style="border-bottom: 1px solid #f1f5f9;">
                            <td style="padding: 10px;">
                                <input type="checkbox" name="selectedOrders" value="<%= o.get("id") %>">
                            </td>
                            <td><strong><%= o.get("student") %></strong></td>
                            <td><%= o.get("item") %></td>
                            <td><small><%= o.get("date") %></small></td>
                        </tr>
                    <% 
                            } 
                        } else { 
                    %>
                        <tr>
                            <td colspan="4" style="text-align: center; padding: 20px; color: #94a3b8;">No pending orders to fulfill.</td>
                        </tr>
                    <% } %>
                </tbody>
            </table>

            <% if (orders != null && !orders.isEmpty()) { %>
                <div style="margin-top: 20px; display: flex; gap: 10px;">
                    <button type="submit" name="decision" value="REJECTED" class="btn-submit" style="background: #ef4444; width: auto;">Reject & Refund Selected</button>
                    <button type="submit" name="decision" value="APPROVED" class="btn-submit" style="background: #10b981; width: auto;">Approve & Mark Completed</button>
                </div>
            <% } %>
        </form>
    </div>
</div>

<div id="extensionModal" class="modal-overlay" style="display:none;">
    <div class="card" style="width: 400px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <h3>Request Limit Extension</h3>
            <button onclick="document.getElementById('extensionModal').style.display='none'" class="btn-close">✕</button>
        </div>
        <form action="rewardAction" method="POST">
            <input type="hidden" name="action" value="requestLimitIncrease">
            <label style="font-weight: bold; font-size: 13px; color: #64748b;">ADDITIONAL AMOUNT NEEDED (₹)</label>
            <input type="number" name="amount" placeholder="e.g. 50.00" step="0.01" required style="margin-bottom: 15px;">
            
            <label style="font-weight: bold; font-size: 13px; color: #64748b;">REASON FOR EXTENSION</label>
            <textarea name="reason" placeholder="Explain why you need extra funds for today..." required style="width: 100%; height: 80px; border: 1px solid #e2e8f0; border-radius: 8px; padding: 10px; margin-bottom: 15px;"></textarea>
            
            <button type="submit" class="btn-submit" style="width:100%; background:#6366f1;">Send Request to Admin</button>
        </form>
    </div>
</div>

<div id="rewardGridModal" class="modal-overlay" style="display:none;">
    <div class="card" style="width: 90%; max-width: 600px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 25px;">
            <h2 id="gridModalTitle" style="margin:0;">Select Block</h2>
            <button onclick="document.getElementById('rewardGridModal').style.display='none'" class="btn-close">✕</button>
        </div>
        <div id="rewardGridContainer" style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px;">
            </div>
    </div>
</div>

<div id="rewardConfigModal" class="modal-overlay" style="display:none;">
    <div class="card" style="width: 400px;">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
            <h3>Manage Reward Blocks</h3>
            <button onclick="document.getElementById('rewardConfigModal').style.display='none'" class="btn-close">✕</button>
        </div>
        <div id="rewardBlockList" class="scroll-area" style="max-height: 200px; margin-bottom: 20px;">
            <%
                List<Map<String, Object>> tRewards = (List<Map<String, Object>>) request.getAttribute("teacherRewardTypes");
                if (tRewards != null && !tRewards.isEmpty()) {
                    for (Map<String, Object> r : tRewards) {
            %>
            <div class="reward-item" style="display:flex; justify-content:space-between; align-items:center; padding:10px; border:1px solid #f1f5f9; border-radius:8px; margin-bottom:8px;">
                <span><strong><%= r.get("name") %></strong> (<%= r.get("amount") %>)</span>
                <button class="btn-delete" style="background:#ef4444; color:white; border:none; padding:5px 10px; border-radius:6px; cursor:pointer;" onclick="deleteRewardType(<%= r.get("id") %>)">Delete</button>
            </div>
            <% } } %>
        </div>
        <form id="addRewardForm" onsubmit="addRewardType(event)">
            <input type="text" id="newRewardName" placeholder="Block Name" required>
            <input type="number" id="newRewardAmount" placeholder="Value" step="0.01" required>
            <input type="text" id="newRewardIcon" placeholder="Emoji Icon" required>
            <button type="submit" class="btn-submit" style="width:100%; background:#8b5cf6;">Add New Block</button>
        </form>
    </div>
</div>

<form id="rewardSubmitForm" action="rewardAction" method="POST" style="display:none;">
    <input type="hidden" name="action" value="processReward">
    <input type="hidden" name="rewardId" id="finalRewardId">
</form>

<script src="${pageContext.request.contextPath}/js/teacher_dashboard.js"></script>
</body>
</html>