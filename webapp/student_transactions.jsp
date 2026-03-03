<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Financial Audit - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/teacher_dashboard.css">
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin-bottom: 20px;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    <nav>
        <a href="teacherDashboard" class="sidebar-link">🏠 Dashboard Overview</a>
        <a href="markAttendance" class="sidebar-link">📝 Mark Attendance</a>
        <a href="teacherDashboard?tab=marketplace" class="sidebar-link">🏪 Marketplace Manager</a>
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link active">💰 Financial Ledger</a>
        <a href="login.jsp" class="sidebar-link logout">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    <div class="breadcrumb">
        <a href="studentTransactions">Ledger</a> 
        <% if(request.getAttribute("selectedClassId") != null) { %> &nbsp;>&nbsp; Class View <% } %>
        <% if(request.getAttribute("targetStudentName") != null) { %> &nbsp;>&nbsp; <%= request.getAttribute("targetStudentName") %> <% } %>
    </div>

    <div class="card" style="max-width: 500px;">
        <h3>1. Audit by Class</h3>
        <form action="studentTransactions" method="GET">
            <select name="classId" onchange="this.form.submit()" style="margin-bottom:0;">
                <option value="">-- Choose Class to View Students --</option>
                <% List<Map<String, Object>> classes = (List<Map<String, Object>>)request.getAttribute("classes");
                   if(classes != null) for(Map<String, Object> c : classes) { %>
                    <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(request.getAttribute("selectedClassId"))) ? "selected" : "" %>><%= c.get("name") %></option>
                <% } %>
            </select>
        </form>
    </div>

    <% List<User> students = (List<User>)request.getAttribute("students"); 
       if(students != null) { %>
    <div class="card">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
            <h3 style="margin:0;">2. Students in Class</h3>
            <small style="color: #64748b;"><%= students.size() %> Students Found</small>
        </div>
        
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" id="studentSearch" onkeyup="filterStudents()" placeholder="Search students by name or roll no...">
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>Roll No</th>
                    <th>Name (Click to view History)</th>
                    <th>Current Balance</th>
                </tr>
            </thead>
            <tbody id="studentBody">
                <% for(User s : students) { %>
                <tr class="student-row">
                    <td><%= s.getRollNo() %></td>
                    <td>
                        <a href="studentTransactions?classId=<%= request.getAttribute("selectedClassId") %>&studentId=<%= s.getId() %>" style="color:#3182ce; text-decoration:none; font-weight:600;">
                            <%= s.getUsername() %>
                        </a>
                    </td>
                    <%-- FIXED LINE: Added formatting for 2 decimal places --%>
                    <td><strong style="color:#10b981;">$<%= String.format("%.2f", s.getBalance()) %></strong></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>

    <% List<Map<String, Object>> txs = (List<Map<String, Object>>)request.getAttribute("transactions");
       if(txs != null) { %>
    <div class="card" style="border-top: 4px solid #3182ce;">
        <h3>3. Transaction History for: <%= request.getAttribute("targetStudentName") %></h3>
        
        <div class="search-container">
            <span class="search-icon">🔍</span>
            <input type="text" id="txSearch" onkeyup="filterTx()" placeholder="Filter history by sender, type, or date...">
        </div>
        
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Sender</th>
                    <th>Receiver</th>
                    <th>Amount</th>
                    <th>Type</th>
                </tr>
            </thead>
            <tbody id="txBody">
                <% for(Map<String, Object> t : txs) { %>
                <tr class="tx-row">
                    <td><small style="color:#64748b;"><%= t.get("date") %></small></td>
                    <td><%= t.get("sender") %></td>
                    <td><%= t.get("receiver") %></td>
                    <%-- FIXED LINE: Added formatting for 2 decimal places --%>
                    <td><strong>$<%= String.format("%.2f", t.get("amount")) %></strong></td>
                    <td>
                        <span class="badge <%= t.get("type").toString().equalsIgnoreCase("REWARD") || t.get("type").toString().equalsIgnoreCase("Salary") ? "bg-salary" : "bg-transfer" %>">
                            <%= t.get("type") %>
                        </span>
                    </td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<script>
function filterStudents() {
    const q = document.getElementById('studentSearch').value.toLowerCase();
    document.querySelectorAll('.student-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}

function filterTx() {
    const q = document.getElementById('txSearch').value.toLowerCase();
    document.querySelectorAll('.tx-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}

window.onload = function() {
    console.log("Financial Ledger Loaded");
};
</script>
</body>
</html>