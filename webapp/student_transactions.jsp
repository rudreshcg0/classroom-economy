<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Financial Audit - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f8f9fa; margin: 0; display: flex; }
        .sidebar { width: 250px; background: #2d3436; color: white; height: 100vh; padding: 25px; position: fixed; }
        .main-content { margin-left: 280px; padding: 30px; width: 100%; max-width: 1200px; }
        .card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        .breadcrumb { margin-bottom: 20px; font-size: 14px; color: #636e72; }
        .breadcrumb a { color: #0984e3; text-decoration: none; }
        .student-link { color: #0984e3; font-weight: bold; text-decoration: none; cursor: pointer; }
        .student-link:hover { text-decoration: underline; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .bg-salary { background: #c6f6d5; color: #2f855a; }
        .bg-transfer { background: #bee3f8; color: #2b6cb0; }
        
        /* New Styles for Search Bars */
        .search-input { 
            width: 100%; 
            padding: 12px; 
            border: 1px solid #cbd5e0; 
            border-radius: 8px; 
            margin-top: 10px;
            box-sizing: border-box;
            font-size: 14px;
        }
        .search-input:focus { outline: none; border-color: #3182ce; box-shadow: 0 0 0 3px rgba(49, 130, 206, 0.1); }
    </style>
</head>
<body>

<div class="sidebar">
    <h2 style="color: #00cec9;">VCES Admin</h2>
    <a href="teacherDashboard" style="color: #dfe6e9; text-decoration: none; display: block; margin: 15px 0;">🏠 Dashboard</a>
    <a href="manageStudents" style="color: #dfe6e9; text-decoration: none; display: block; margin: 15px 0;">👥 Student Registry</a>
    <a href="studentTransactions" style="color: white; font-weight: bold; text-decoration: none; display: block; margin: 15px 0; background: #0984e3; padding: 10px; border-radius: 8px;">💰 Financial Ledger</a>
    <a href="login.jsp" style="color: #ff7675; text-decoration: none; display: block; margin-top: 30px;">Logout</a>
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

<script>
// Search Students Logic
function filterStudents() {
    const q = document.getElementById('studentSearch').value.toLowerCase();
    document.querySelectorAll('.student-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? "" : "none";
    });
}

// Search Transactions Logic
function filterTx() {
    const q = document.getElementById('txSearch').value.toLowerCase();
    document.querySelectorAll('.tx-row').forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? "" : "none";
    });
}
</script>
</body>
</html>