<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List" %>
<%@ page import="models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Teacher Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f7f6; }
        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .balance-box { background: #e7f3ff; padding: 15px; border-radius: 5px; margin-bottom: 20px; border-left: 5px solid #2196F3; }
        table { width: 100%; border-collapse: collapse; margin-top: 10px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #ddd; }
        th { background-color: #2196F3; color: white; }
        tr:hover { background-color: #f1f1f1; }
    </style>
</head>
<body>

<div class="container">
    <h1>Welcome to your Dashboard</h1>
    
    <div class="balance-box">
        <strong>Teacher Allowance Balance:</strong> 
        $<%= request.getAttribute("allowance") != null ? request.getAttribute("allowance") : "0.00" %>
    </div>

    <h3>Your Students</h3>
    <table>
        <thead>
            <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Wallet Balance</th>
            </tr>
        </thead>
        <tbody>
            <% 
                List<User> students = (List<User>) request.getAttribute("students");
                if (students != null && !students.isEmpty()) {
                    for (User s : students) {
            %>
            <tr>
                <td><%= s.getId() %></td>
                <td><%= s.getUsername() %></td>
                <td>$<%= s.getBalance() %></td>
            </tr>
            <% 
                    }
                } else { 
            %>
            <tr>
                <td colspan="3" style="text-align:center;">No students found for this school.</td>
            </tr>
            <% } %>
        </tbody>
    </table>
    
    <br>
    <a href="login.html">Logout</a>
</div>

</body>
</html>