<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- This line fixes the "User cannot be resolved" error --%>
<%@ page import="models.User" %>

<!DOCTYPE html>
<html>
<head>
    <title>Student Dashboard</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; background-color: #f4f7f6; margin: 40px; }
        .container { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); max-width: 600px; margin: auto; }
        h1 { color: #2c3e50; border-bottom: 2px solid #4CAF50; padding-bottom: 10px; }
        .balance-box { background: #e8f5e9; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 8px solid #4CAF50; }
        .balance-amount { font-size: 24px; color: #2e7d32; font-weight: bold; }
        .logout-btn { display: inline-block; margin-top: 20px; color: #e74c3c; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>

<div class="container">
    <% 
        // Safely get the user from session
        User student = (User) session.getAttribute("user");
        String username = (student != null) ? student.getUsername() : "Student";
    %>
    
    <h1>Welcome, <%= username %>!</h1>
    
    <div class="balance-box">
        <strong>Your Current Balance:</strong><br>
        <span class="balance-amount">
            $<%= request.getAttribute("balance") != null ? request.getAttribute("balance") : "0.00" %>
        </span>
    </div>

    <p>Great job! Keep earning rewards through your classroom activities.</p>
    
    <a href="login.html" class="logout-btn">Logout</a>
</div>

</body>
</html>