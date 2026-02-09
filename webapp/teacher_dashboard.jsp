<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Dashboard - VCES</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background-color: #f4f7f6; }
        .container { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .balance-box { background: #e7f3ff; padding: 15px; border-radius: 8px; margin-bottom: 20px; border-left: 5px solid #2196F3; display: inline-block; min-width: 250px; }
        
        /* Attendance Form Styling */
        .attendance-section { margin-top: 30px; border-top: 2px solid #eee; padding-top: 20px; }
        .class-selector { padding: 10px; border-radius: 5px; border: 1px solid #ddd; margin-bottom: 20px; width: 300px; font-size: 16px; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #ddd; }
        th { background-color: #2196F3; color: white; }
        tr:hover { background-color: #f9f9f9; }
        
        .btn-submit { background-color: #4CAF50; color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; font-weight: bold; margin-top: 20px; }
        .btn-submit:hover { background-color: #45a049; }
        .success-msg { color: #2e7d32; background: #e8f5e9; padding: 10px; border-radius: 5px; margin-bottom: 15px; }
    </style>
</head>
<body>

<div class="container">
    <h1>Teacher Control Panel</h1>

    <% if(request.getParameter("success") != null) { %>
        <div class="success-msg">✅ Attendance marked and payments processed successfully!</div>
    <% } %>
    
    <div class="balance-box">
        <strong>Your Reward Budget:</strong> 
        <span style="font-size: 1.2em; color: #1565C0;">$<%= request.getAttribute("allowance") != null ? request.getAttribute("allowance") : "0.00" %></span>
    </div>

    <div class="attendance-section">
        <h3>Daily Attendance & Automatic Pay</h3>
        <p>Select a class and mark students present to mint their daily reward.</p>

        <form action="markAttendance" method="POST">
            <input type="hidden" name="schoolId" value="<%= ((User)session.getAttribute("user")).getSchoolId() %>">

            <label for="classId"><strong>Select Class:</strong></label><br>
            <select name="classId" class="class-selector" required>
                <option value="">-- Choose a Class --</option>
                <% 
                    List<Map<String, Object>> classes = (List<Map<String, Object>>) request.getAttribute("classes");
                    if (classes != null) {
                        for (Map<String, Object> c : classes) {
                %>
                    <option value="<%= c.get("id") %>"><%= c.get("name") %> ($<%= c.get("pay") %>/day)</option>
                <% 
                        }
                    } 
                %>
            </select>

            <table>
                <thead>
                    <tr>
                        <th style="width: 50px;">Present</th>
                        <th>Student Username</th>
                        <th>Current Wallet</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                        List<User> students = (List<User>) request.getAttribute("students");
                        if (students != null && !students.isEmpty()) {
                            for (User s : students) {
                    %>
                    <tr>
                        <td><input type="checkbox" name="presentStudents" value="<%= s.getId() %>" style="transform: scale(1.5);"></td>
                        <td><%= s.getUsername() %></td>
                        <td>$<%= s.getBalance() %></td>
                    </tr>
                    <% 
                            }
                        } else { 
                    %>
                    <tr>
                        <td colspan="3" style="text-align:center;">No students registered in your school.</td>
                    </tr>
                    <% } %>
                </tbody>
            </table>

            <button type="submit" class="btn-submit">Submit Attendance & Pay Students</button>
        </form>
    </div>
    
    <br><br>
    <a href="login.html" style="color: #e74c3c; text-decoration: none; font-weight: bold;">Logout</a>
</div>

</body>
</html>