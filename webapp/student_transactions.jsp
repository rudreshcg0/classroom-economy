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
        <% if(request.getAttribute("selectedClassId") != null) { %> > Class View <% } %>
        <% if(request.getAttribute("targetStudentName") != null) { %> > <%= request.getAttribute("targetStudentName") %> <% } %>
    </div>

    <div class="card">
        <h3>1. Audit by Class</h3>
        <form action="studentTransactions" method="GET">
            <select name="classId" onchange="this.form.submit()" style="padding:10px; width:300px; border-radius:8px; border:1px solid #ddd;">
                <option value="">-- Choose Class --</option>
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
        <h3>2. Students in Class</h3>
        <input type="text" id="studentSearch" onkeyup="filterStudents()" placeholder="Search students by name or roll no..." class="search-input">
        
        <table>
            <thead><tr><th>Roll No</th><th>Name</th><th>Balance</th></tr></thead>
            <tbody id="studentBody">
                <% for(User s : students) { %>
                <tr class="student-row">
                    <td><%= s.getRollNo() %></td>
                    <td>
                        <a href="studentTransactions?classId=<%= request.getAttribute("selectedClassId") %>&studentId=<%= s.getId() %>" class="student-link">
                            <%= s.getUsername() %>
                        </a>
                    </td>
                    <td>$<%= s.getBalance() %></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>

    <% List<Map<String, Object>> txs = (List<Map<String, Object>>)request.getAttribute("transactions");
       if(txs != null) { %>
    <div class="card">
        <h3>3. History for: <%= request.getAttribute("targetStudentName") %></h3>
        <input type="text" id="txSearch" onkeyup="filterTx()" placeholder="Filter history by sender, type, or date..." class="search-input">
        
        <table>
            <thead><tr><th>Date</th><th>Sender</th><th>Receiver</th><th>Amount</th><th>Type</th></tr></thead>
            <tbody id="txBody">
                <% for(Map<String, Object> t : txs) { %>
                <tr class="tx-row">
                    <td><small><%= t.get("date") %></small></td>
                    <td><%= t.get("sender") %></td>
                    <td><%= t.get("receiver") %></td>
                    <td style="font-weight:bold">$<%= t.get("amount") %></td>
                    <td><span class="badge <%= t.get("type").toString().equals("Salary") ? "bg-salary" : "bg-transfer" %>"><%= t.get("type") %></span></td>
                </tr>
                <% } %>
            </tbody>
        </table>
    </div>
    <% } %>
</div>

<script src="${pageContext.request.contextPath}/js/teacher_dashboard.js"></script>
<script>
// Search Students Logic
function filterStudents() {
    const q = document.getElementById('studentSearch').value.toLowerCase();
    document.querySelectorAll('.student-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}

// Search Transactions Logic
function filterTx() {
    const q = document.getElementById('txSearch').value.toLowerCase();
    document.querySelectorAll('.tx-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? '' : 'none';
    });
}
</script>
</body>
</html>