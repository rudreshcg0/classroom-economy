<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>School Admin Hub</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; display: flex; background: #f0f2f5; }
        .sidebar { width: 250px; background: #1a202c; color: white; height: 100vh; padding: 20px; position: fixed; }
        .main-content { margin-left: 290px; padding: 40px; width: calc(100% - 330px); }
        .card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 25px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; margin-bottom: 25px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; background: white; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #edf2f7; }
        th { background: #4a5568; color: white; font-size: 13px; text-transform: uppercase; }
        input, select { width: 100%; padding: 10px; margin-bottom: 15px; border: 1px solid #ddd; border-radius: 5px; box-sizing: border-box; }
        .btn { border: none; padding: 12px; border-radius: 5px; cursor: pointer; color: white; font-weight: bold; width: 100%; transition: 0.3s; }
        .btn:hover { opacity: 0.8; }
        .btn-del { background: #e53e3e; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 11px; font-weight: bold; }
        .btn-del:hover { background: #c53030; }
        .badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .badge-teacher { background: #ebf8ff; color: #3182ce; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p>Logged in: <strong>${sessionScope.user.username}</strong></p>
    <p>School ID: <strong>${sessionScope.user.schoolId}</strong></p>
    <hr style="border: 0.5px solid #4a5568; margin: 20px 0;">
    <a href="login.html" style="color: #fc8181; text-decoration: none; font-weight: bold;">Logout</a>
</div>

<div class="main-content">
    <h1>School Management Dashboard</h1>

    <div class="grid">
        <div class="card">
            <h3>+ Register Teacher</h3>
            <form action="adminAction" method="POST">
                <input type="hidden" name="action" value="addTeacher">
                <input type="text" name="username" placeholder="Teacher Username" required>
                <input type="password" name="password" placeholder="Password" required>
                <button type="submit" class="btn" style="background:#3182ce;">Add Teacher</button>
            </form>
        </div>

        <div class="card">
            <h3>+ Create Class</h3>
            <form action="adminAction" method="POST">
                <input type="hidden" name="action" value="addClass">
                <input type="text" name="className" placeholder="Class Name" required>
                <input type="number" name="payRate" placeholder="Pay Rate" step="0.1" required>
                <button type="submit" class="btn" style="background:#38a169;">Create Class</button>
            </form>
        </div>

        <div class="card">
            <h3>🔗 Link Teacher</h3>
            <form action="adminAction" method="POST">
                <input type="hidden" name="action" value="assignTeacher">
                <select name="classId" required>
                    <option value="">-- Select Class --</option>
                    <% List<Map<String, Object>> classList = (List<Map<String, Object>>) request.getAttribute("classList");
                       if(classList != null) for(Map<String, Object> c : classList) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                    <% } %>
                </select>
                <select name="teacherId" required>
                    <option value="">-- Select Teacher --</option>
                    <% List<User> users = (List<User>) request.getAttribute("allUsers");
                       if(users != null) for(User u : users) { 
                           if(u.getRole().equalsIgnoreCase("teacher")) { %>
                            <option value="<%= u.getId() %>"><%= u.getUsername() %></option>
                    <% } } %>
                </select>
                <button type="submit" class="btn" style="background:#805ad5;">Assign Teacher</button>
            </form>
        </div>
    </div>

    <div class="card">
        <h3>Current Classes & Assignments</h3>
        <table>
            <thead>
                <tr><th>Class Name</th><th>Assigned Teacher</th><th>Pay</th><th>Action</th></tr>
            </thead>
            <tbody>
                <% if(classList != null && !classList.isEmpty()) { 
                    for(Map<String, Object> c : classList) { %>
                    <tr>
                        <td><strong><%= c.get("name") %></strong></td>
                        <td><span class="badge-teacher"><%= c.get("teacher") %></span></td>
                        <td>$<%= c.get("pay") %></td>
                        <td>
                            <form action="adminAction" method="POST" onsubmit="return confirm('Delete this class?');">
                                <input type="hidden" name="action" value="deleteClass">
                                <input type="hidden" name="id" value="<%= c.get("id") %>">
                                <button type="submit" class="btn-del">Delete Class</button>
                            </form>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr><td colspan="4">No classes found.</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <div class="card">
        <h3>Registered Staff & Students</h3>
        <table>
            <thead>
                <tr><th>ID</th><th>Username</th><th>Role</th><th>Action</th></tr>
            </thead>
            <tbody>
                <% if(users != null && !users.isEmpty()) { 
                    for(User u : users) { %>
                    <tr>
                        <td><%= u.getId() %></td>
                        <td><%= u.getUsername() %></td>
                        <td><span class="badge badge-teacher"><%= u.getRole().toUpperCase() %></span></td>
                        <td>
                            <form action="adminAction" method="POST" onsubmit="return confirm('Delete this user?');">
                                <input type="hidden" name="action" value="deleteUser">
                                <input type="hidden" name="id" value="<%= u.getId() %>">
                                <button type="submit" class="btn-del">Delete User</button>
                            </form>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr><td colspan="4">No users found.</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>
</body>
</html>