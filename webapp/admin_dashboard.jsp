<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Super Admin Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; display: flex; background-color: #f0f2f5; }
        .sidebar { width: 250px; background-color: #1a202c; color: white; height: 100vh; padding: 20px; position: fixed; }
        .main-content { margin-left: 290px; padding: 40px; width: 100%; }
        .card { background: white; border-radius: 10px; padding: 20px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 30px; }
        h1, h2 { color: #2d3748; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { text-align: left; padding: 15px; border-bottom: 1px solid #edf2f7; }
        th { background-color: #4a5568; color: white; text-transform: uppercase; font-size: 12px; }
        .badge { padding: 5px 10px; border-radius: 20px; font-size: 12px; font-weight: bold; }
        .badge-teacher { background-color: #ebf8ff; color: #3182ce; }
        .badge-student { background-color: #f0fff4; color: #38a169; }
        .stat-val { font-weight: bold; color: #2b6cb0; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>Admin Center</h2>
    <p>Logged in as: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.5px solid #4a5568;">
    <ul style="list-style: none; padding: 0;">
        <li style="padding: 10px 0;"><a href="#" style="color: white; text-decoration: none;">Dashboard Home</a></li>
        <li style="padding: 10px 0;"><a href="login.html" style="color: #fc8181; text-decoration: none;">Logout</a></li>
    </ul>
</div>

<div class="main-content">
    <h1>System Overview</h1>

    <div class="card">
        <h2>Registered Schools & Staffing</h2>
        <table>
            <thead>
                <tr>
                    <th>School Name</th>
                    <th>Teacher Count</th>
                </tr>
            </thead>
            <tbody>
                <% 
                    List<Map<String, Object>> stats = (List<Map<String, Object>>) request.getAttribute("schoolStats");
                    if (stats != null && !stats.isEmpty()) {
                        for (Map<String, Object> s : stats) {
                %>
                <tr>
                    <td><%= s.get("name") %></td>
                    <td class="stat-val"><%= s.get("count") %> Teachers</td>
                </tr>
                <% 
                        }
                    } else { 
                %>
                <tr><td colspan="2">No school data found.</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <div class="card">
        <h2>All System Users</h2>
        <table>
            <thead>
                <tr>
                    <th>User ID</th>
                    <th>Username</th>
                    <th>Role</th>
                    <th>School ID</th>
                </tr>
            </thead>
            <tbody>
                <% 
                    List<User> allUsers = (List<User>) request.getAttribute("allUsers");
                    if (allUsers != null && !allUsers.isEmpty()) {
                        for (User u : allUsers) {
                %>
                <tr>
                    <td><%= u.getId() %></td>
                    <td><%= u.getUsername() %></td>
                    <td>
                        <span class="badge <%= u.getRole().equalsIgnoreCase("teacher") ? "badge-teacher" : "badge-student" %>">
                            <%= u.getRole().toUpperCase() %>
                        </span>
                    </td>
                    <td><%= u.getSchoolId() %></td>
                </tr>
                <% 
                        }
                    } else { 
                %>
                <tr><td colspan="4">No users registered yet.</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>