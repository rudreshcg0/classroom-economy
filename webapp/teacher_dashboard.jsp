<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background-color: #f0f2f5; display: flex; }
        .sidebar { width: 260px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; }
        .main-content { margin-left: 310px; padding: 40px; width: 100%; }
        .card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .balance-box { background: #ebf8ff; color: #2b6cb0; padding: 20px; border-radius: 10px; border-left: 5px solid #3182ce; margin-bottom: 25px; }
        .nav-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin-top: 20px; }
        .nav-card { background: white; padding: 30px; border-radius: 12px; text-align: center; text-decoration: none; color: #2d3748; box-shadow: 0 4px 6px rgba(0,0,0,0.05); transition: 0.3s; border: 1px solid #e2e8f0; }
        .nav-card:hover { transform: translateY(-5px); box-shadow: 0 10px 15px rgba(0,0,0,0.1); border-color: #3182ce; }
        .btn-submit { background-color: #4CAF50; color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; font-weight: bold; width: 100%; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>Teacher Panel</h2>
    <p>Welcome, <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
    <a href="login.html" style="color: #fc8181; text-decoration: none; font-weight: bold;">Logout</a>
</div>

<div class="main-content">
    <h1>Dashboard Overview</h1>

    <div class="balance-box">
        <small>Current Reward Budget</small>
        <h2 style="margin: 5px 0;">$${allowance != null ? allowance : "0.00"}</h2>
    </div>

    <div class="nav-grid">
        <a href="manageStudents" class="nav-card">
            <h3 style="color: #3182ce;">👥 Student Management</h3>
            <p>Add/Delete students and link them to classes in bulk.</p>
        </a>
        <div class="nav-card" style="cursor: default;">
            <h3 style="color: #38a169;">📝 Quick Attendance</h3>
            <p>Select a class below to pay students for today.</p>
        </div>
    </div>

    <div class="card" style="margin-top: 30px;">
        <h3>Select Class for Attendance Payment</h3>
        <form action="markAttendance" method="GET">
            <select name="classId" required style="padding: 12px; width: 100%; margin-bottom: 15px; border-radius: 8px; border: 1px solid #cbd5e0;">
                <option value="">-- Choose Class to Start Marking --</option>
                <% 
                    List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
                    if (classes != null) {
                        for (Map<String, Object> c : classes) {
                %>
                    <option value="<%= c.get("id") %>"><%= c.get("name") %> ($<%= c.get("pay") %>/day)</option>
                <% } } %>
            </select>
            <button type="submit" class="btn-submit">Start Attendance Session</button>
        </form>
    </div>
</div>

</body>
</html>