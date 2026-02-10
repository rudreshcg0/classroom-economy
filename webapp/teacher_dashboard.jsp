<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Hub - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background-color: #f0f2f5; display: flex; }
        .sidebar { width: 260px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; }
        .sidebar h2 { color: #63b3ed; margin-bottom: 30px; }
        .sidebar-link { display: block; color: #cbd5e0; text-decoration: none; padding: 12px; border-radius: 8px; margin-bottom: 10px; transition: 0.3s; }
        .sidebar-link:hover { background: #2d3748; color: white; }
        .sidebar-link.active { background: #3182ce; color: white; }
        
        .main-content { margin-left: 310px; padding: 40px; width: calc(100% - 310px); }
        .card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        
        .balance-box { background: #ebf8ff; color: #2b6cb0; padding: 20px; border-radius: 10px; border-left: 5px solid #3182ce; margin-bottom: 25px; }
        
        .nav-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin-top: 20px; }
        .nav-card { background: white; padding: 25px; border-radius: 12px; text-align: center; text-decoration: none; color: #2d3748; box-shadow: 0 4px 6px rgba(0,0,0,0.05); transition: 0.3s; border: 1px solid #e2e8f0; }
        .nav-card:hover { transform: translateY(-5px); box-shadow: 0 10px 15px rgba(0,0,0,0.1); border-color: #3182ce; }
        
        .btn-submit { background-color: #38a169; color: white; padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; font-weight: bold; width: 100%; transition: 0.2s; }
        .btn-submit:hover { background-color: #2f855a; }
        
        select { padding: 12px; width: 100%; margin-bottom: 15px; border-radius: 8px; border: 1px solid #cbd5e0; font-size: 15px; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
    
    <nav>
        <a href="teacherDashboard" class="sidebar-link active">🏠 Dashboard Overview</a>
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link">💰 Financial Ledger</a>
        <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
        <a href="login.html" style="color: #fc8181;" class="sidebar-link">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    <h1>Dashboard Overview</h1>

    <div class="balance-box">
        <small style="text-transform: uppercase; font-weight: bold; letter-spacing: 1px;">Reward Budget Balance</small>
        <h2 style="margin: 5px 0; font-size: 32px;">$${allowance != null ? allowance : "0.00"}</h2>
    </div>

    <div class="nav-grid">
        <a href="manageStudents" class="nav-card">
            <h3 style="color: #3182ce; margin-top: 0;">👥 Student Registry</h3>
            <p style="color: #718096; font-size: 14px;">Register accounts, enroll students in classes, or terminate records.</p>
        </a>

        <a href="studentTransactions" class="nav-card">
            <h3 style="color: #805ad5; margin-top: 0;">💰 Financial Ledger</h3>
            <p style="color: #718096; font-size: 14px;">Audit classroom spending, salary disbursements, and peer-to-peer transfers.</p>
        </a>
    </div>

    <div class="card" style="margin-top: 30px;">
        <h3 style="margin-top: 0; display: flex; align-items: center; gap: 10px;">
            <span style="color: #38a169;">📝</span> Quick Attendance Session
        </h3>
        <p style="color: #718096; font-size: 14px; margin-bottom: 20px;">Select a class to begin marking attendance and processing automated rewards.</p>
        
        <form action="markAttendance" method="GET">
            <select name="classId" required>
                <option value="">-- Choose Class to Start Marking --</option>
                <% 
                    List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
                    if (classes != null) {
                        for (Map<String, Object> c : classes) {
                %>
                    <option value="<%= c.get("id") %>"><%= c.get("name") %> (Pay: $<%= c.get("pay") %>/day)</option>
                <%      } 
                    } 
                %>
            </select>
            <button type="submit" class="btn-submit">Launch Attendance Console</button>
        </form>
    </div>
</div>

</body>
</html>