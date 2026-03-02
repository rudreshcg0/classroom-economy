<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>School Admin Hub</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin_dashboard.css">
</head>
<body>

<% 
    String currentView = (String)request.getAttribute("currentView"); 
    String selectedClass = (String)request.getAttribute("selectedClassId"); 
    // Default to panel-register if no activeTab is provided in the URL
    String activeTab = request.getParameter("activeTab") != null ? request.getParameter("activeTab") : "panel-register";
%>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin: 10px 0 0;">Admin: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border:0.5px solid #4a5568;">
    <nav>
        <a href="adminDashboard?view=management" class="<%= "management".equals(currentView) ? "active" : "" %>">⚙️ Management</a>
        <a href="adminDashboard?view=ledger" class="<%= "ledger".equals(currentView) ? "active" : "" %>">💰 Financial Ledger</a>
        <hr style="border:0.5px solid #4a5568; margin: 20px 0;">
        <a href="login.jsp" style="color:#fc8181;">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    
    <% if ("management".equals(currentView)) { %>
        <h1>School Management</h1>

        <div class="admin-actions">
            <button type="button" class="btn-tab" data-target="panel-register">Register Staff</button>
            <button type="button" class="btn-tab" data-target="panel-classlink">Class Setup & Linking</button>
            <button type="button" class="btn-tab" data-target="panel-registry">Class & Enrollment Management</button>
        </div>

        <div id="panel-register" class="action-panel hidden">
            <div class="card">
                <h3>Register Staff</h3>
                <form action="adminAction" method="POST">
                    <input type="hidden" name="action" value="addTeacher">
                    <input type="text" name="username" placeholder="Full Name" required>
                    <input type="password" name="password" placeholder="Password" required>
                    <button type="submit" class="btn-main" style="background:#3182ce; color:white;">Add Teacher Account</button>
                </form>
            </div>
        </div>

        <div id="panel-classlink" class="action-panel hidden">
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
                <form action="adminAction" method="POST" style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 10px;">
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

                <form action="adminAction" method="POST" onsubmit="return confirm('Delete this class permanently? This cannot be undone.');" style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 10px;">
                    <input type="hidden" name="action" value="deleteClass">
                    <select name="id" required>
                        <option value="">Select Class to Delete</option>
                        <% if(cl != null) for(Map<String, Object> c : cl) { %>
                            <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                        <% } %>
                    </select>
                    <input type="hidden" name="view" value="management">
                    <input type="hidden" name="activeTab" value="panel-classlink">
                    <button type="submit" class="btn-del" style="width: 100%; margin-top: 8px;">Delete Class</button>
                </form>
            </div>
        </div>

        <div id="panel-registry" class="action-panel hidden">
            <div class="card">
                <h3>Class & Enrollment Management</h3>
                <form action="adminDashboard" method="GET" id="registryJump">
                    <input type="hidden" name="view" value="management">
                    <input type="hidden" name="activeTab" value="panel-registry">
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
                        <div class="section-header">Assigned Staff <input type="text" class="search-mini" onkeyup="filterTable(this, 'teacherTable')" placeholder="Search..."></div>
                        <table id="teacherTable">
                            <% List<User> ct = (List<User>)request.getAttribute("classTeachers");
                               if(ct != null && !ct.isEmpty()) { for(User t : ct) { %>
                                <tr>
                                    <td width="30px"><input type="checkbox" name="id" value="<%= t.getId() %>"></td>
                                    <td><strong><%= t.getUsername() %></strong></td>
                                    <td align="right"><button type="button" class="btn-unlink" onclick="unlinkTeacher('<%= selectedClass %>')">Unlink</button></td>
                                </tr>
                            <% } } %>
                        </table>
                        <div class="section-header">Enrolled Roster <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentTable')" placeholder="Search..."></div>
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
                        <button type="submit" class="btn-del" style="margin-top:20px; width:100%;" onclick="return confirm('Terminate selected?')">Terminate Selected</button>
                    </form>
                <% } %>
            </div>
        </div>

    <% } else { %>
        <jsp:include page="includes/admin_ledger.jsp" /> 
    <% } %>
</div>

<form id="unlinkForm" action="adminAction" method="POST" style="display:none;">
    <input type="hidden" name="action" value="assignTeacher">
    <input type="hidden" name="classId" id="unlinkClassId">
    <input type="hidden" name="teacherId" value="0">
</form>

<script>window.ACTIVE_TAB_ID = "<%= activeTab %>";</script>
<script src="${pageContext.request.contextPath}/js/admin_dashboard.js"></script>
</body>
</html>