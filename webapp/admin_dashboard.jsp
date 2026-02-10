<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>School Admin Hub</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background: #f8f9fa; display: flex; }
        .sidebar { width: 260px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; left: 0; top: 0; }
        .sidebar a { display: block; color: #cbd5e0; text-decoration: none; padding: 12px; border-radius: 8px; margin-bottom: 5px; }
        .sidebar a.active { background: #3182ce; color: white; }
        .main-content { margin-left: 285px; padding: 30px; width: calc(100% - 320px); }
        .card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #edf2f7; }
        .section-header { background: #f7fafc; padding: 10px; font-weight: bold; color: #4a5568; border-bottom: 2px solid #e2e8f0; margin-top: 15px; display: flex; justify-content: space-between; align-items: center; }
        .search-mini { padding: 5px 10px; border-radius: 4px; border: 1px solid #ddd; font-size: 12px; width: 150px; }
        input, select, .btn-main { padding: 10px; border-radius: 6px; border: 1px solid #ddd; width: 100%; margin-bottom: 10px; box-sizing: border-box;}
        .btn-del { background: #e53e3e; color: white; border: none; padding: 8px 15px; border-radius: 4px; cursor: pointer; font-weight: bold; }
        .btn-unlink { background: #ed8936; color: white; border: none; padding: 4px 8px; border-radius: 4px; cursor: pointer; font-size: 11px; }
    </style>
</head>
<body>

<% String currentView = (String)request.getAttribute("currentView"); 
   String selectedClass = (String)request.getAttribute("selectedClassId"); %>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <hr style="border:0.5px solid #4a5568;">
    <nav>
        <a href="adminDashboard?view=management" class="<%= "management".equals(currentView) ? "active" : "" %>">⚙️ Management</a>
        <a href="adminDashboard?view=ledger" class="<%= "ledger".equals(currentView) ? "active" : "" %>">💰 Financial Ledger</a>
        <hr style="border:0.5px solid #4a5568; margin: 20px 0;">
        <a href="login.html" style="color:#fc8181;">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    
    <% if ("management".equals(currentView)) { %>
        <h1>School Management</h1>
        <div class="grid">
            <div class="card">
                <h3>Register Staff</h3>
                <form action="adminAction" method="POST">
                    <input type="hidden" name="action" value="addTeacher">
                    <input type="text" name="username" placeholder="Full Name" required>
                    <input type="password" name="password" placeholder="Password" required>
                    <button type="submit" class="btn-main" style="background:#3182ce; color:white;">Add Teacher Account</button>
                </form>
            </div>
            <div class="card">
                <h3>Class Setup & Linking</h3>
                <form action="adminAction" method="POST">
                    <input type="hidden" name="action" value="addClass">
                    <div style="display:flex; gap:10px;">
                        <input type="text" name="className" placeholder="Class Name" required>
                        <input type="number" name="payRate" placeholder="Pay" step="0.1" required>
                    </div>
                    <button type="submit" class="btn-main" style="background:#38a169; color:white;">Create New Class</button>
                </form>
                <form action="adminAction" method="POST" style="border-top: 1px solid #eee; padding-top: 10px;">
                    <input type="hidden" name="action" value="assignTeacher">
                    <select name="classId" required>
                        <option value="">Select Class</option>
                        <% List<Map<String, Object>> cl = (List<Map<String, Object>>)request.getAttribute("classList");
                           if(cl != null) for(Map<String, Object> c : cl) { %>
                            <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                        <% } %>
                    </select>
                    <select name="teacherId" required>
                        <option value="">Select Teacher to Link</option>
                        <% List<User> st = (List<User>)request.getAttribute("schoolTeachers");
                           if(st != null) for(User t : st) { %>
                            <option value="<%= t.getId() %>"><%= t.getUsername() %></option>
                        <% } %>
                    </select>
                    <button type="submit" class="btn-main" style="background:#805ad5; color:white;">Assign Teacher to Class</button>
                </form>
            </div>
        </div>

        <div class="card">
            <h3>Registry Management</h3>
            <form action="adminDashboard" method="GET">
                <input type="hidden" name="view" value="management">
                <select name="classId" onchange="this.form.submit()">
                    <option value="">-- Choose Class to Manage --</option>
                    <% if(cl != null) for(Map<String, Object> c : cl) { %>
                        <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(selectedClass)) ? "selected" : "" %>><%= c.get("name") %></option>
                    <% } %>
                </select>
            </form>

            <% if(selectedClass != null) { %>
                <form action="adminAction" method="POST">
                    <input type="hidden" name="action" value="deleteUser">
                    
                    <div class="section-header">
                        Assigned Staff
                        <input type="text" class="search-mini" onkeyup="filterTable(this, 'teacherTable')" placeholder="Search teachers...">
                    </div>
                    <table id="teacherTable">
                        <% List<User> ct = (List<User>)request.getAttribute("classTeachers");
                           if(ct != null && !ct.isEmpty()) { for(User t : ct) { %>
                            <tr>
                                <td width="30px"><input type="checkbox" name="id" value="<%= t.getId() %>"></td>
                                <td><strong><%= t.getUsername() %></strong></td>
                                <td align="right">
                                    <button type="button" class="btn-unlink" onclick="unlinkTeacher('<%= selectedClass %>')">Unlink from Class</button>
                                </td>
                            </tr>
                        <% } } else { %> <tr><td colspan="3">No teachers assigned.</td></tr> <% } %>
                    </table>

                    <div class="section-header">
                        Enrolled Roster
                        <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentTable')" placeholder="Search students...">
                    </div>
                    <table id="studentTable">
                        <% List<User> cs = (List<User>)request.getAttribute("classStudents");
                           if(cs != null && !cs.isEmpty()) { for(User s : cs) { %>
                            <tr>
                                <td width="30px"><input type="checkbox" name="id" value="<%= s.getId() %>"></td>
                                <td><%= s.getUsername() %></td>
                                <td align="right">Roll: <%= s.getRollNo() %></td>
                            </tr>
                        <% } } %>
                    </table>
                    <button type="submit" class="btn-del" style="margin-top:20px; width:100%;" onclick="return confirm('Delete selected accounts permanently?')">Terminate Selected Accounts</button>
                </form>
            <% } %>
        </div>

    <% } else { %>
        <h1>Financial Audit Ledger</h1>
        <div class="card">
            <form action="adminDashboard" method="GET">
                <input type="hidden" name="view" value="ledger">
                <select name="classId" onchange="this.form.submit()">
                    <option value="">-- Select Class to Audit --</option>
                    <% List<Map<String, Object>> cl = (List<Map<String, Object>>)request.getAttribute("classList");
                       if(cl != null) for(Map<String, Object> c : cl) { %>
                        <option value="<%= c.get("id") %>" <%= (c.get("id").toString().equals(selectedClass)) ? "selected" : "" %>><%= c.get("name") %></option>
                    <% } %>
                </select>
            </form>
        </div>

        <% if(selectedClass != null) { %>
            <div class="grid">
                <div class="card">
                    <div class="section-header">
                        Staff Ledger
                        <input type="text" class="search-mini" onkeyup="filterTable(this, 'staffLedgerList')" placeholder="Filter staff...">
                    </div>
                    <table id="staffLedgerList">
                        <% List<User> ct = (List<User>)request.getAttribute("classTeachers");
                           if(ct != null) for(User t : ct) { %>
                            <tr>
                                <td><strong><%= t.getUsername() %></strong></td>
                                <td align="right"><a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= t.getId() %>">Audit →</a></td>
                            </tr>
                        <% } %>
                    </table>

                    <div class="section-header">
                        Student Ledger
                        <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentLedgerList')" placeholder="Filter students...">
                    </div>
                    <table id="studentLedgerList">
                        <% List<User> cs = (List<User>)request.getAttribute("classStudents");
                           if(cs != null) for(User s : cs) { %>
                            <tr>
                                <td><%= s.getUsername() %></td>
                                <td align="right"><a href="adminDashboard?view=ledger&classId=<%= selectedClass %>&viewUserId=<%= s.getId() %>">View →</a></td>
                            </tr>
                        <% } %>
                    </table>
                </div>

                <% if(request.getAttribute("history") != null) { %>
                    <div class="card">
                        <h3>Ledger: <%= request.getAttribute("targetName") %></h3>
                        <table>
                            <% List<Map<String, Object>> history = (List<Map<String, Object>>)request.getAttribute("history");
                               for(Map<String, Object> h : history) { %>
                                <tr>
                                    <td><small><%= h.get("date") %></small></td>
                                    <td><strong>$<%= h.get("amount") %></strong></td>
                                    <td><%= h.get("type") %></td>
                                </tr>
                            <% } %>
                        </table>
                    </div>
                <% } %>
            </div>
        <% } %>
    <% } %>
</div>

<form id="unlinkForm" action="adminAction" method="POST" style="display:none;">
    <input type="hidden" name="action" value="assignTeacher">
    <input type="hidden" name="classId" id="unlinkClassId">
    <input type="hidden" name="teacherId" value="0"> </form>

<script>
function filterTable(input, tableId) {
    const q = input.value.toLowerCase();
    const rows = document.querySelectorAll('#' + tableId + ' tr');
    rows.forEach(row => {
        row.style.display = row.innerText.toLowerCase().includes(q) ? "" : "none";
    });
}

function unlinkTeacher(classId) {
    if(confirm("Are you sure you want to remove this teacher from the class?")) {
        document.getElementById('unlinkClassId').value = classId;
        document.getElementById('unlinkForm').submit();
    }
}
</script>
</body>
</html>