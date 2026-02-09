<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*" %>
<%@ page import="models.User" %>

<!DOCTYPE html>
<html>
<head>
    <title>My VCES Wallet</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background-color: #f4f7f6; margin: 40px; }
        .container { background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); max-width: 800px; margin: auto; }
        .balance-box { background: #e8f5e9; padding: 20px; border-radius: 8px; margin-bottom: 30px; border-left: 8px solid #4CAF50; }
        .balance-amount { font-size: 32px; color: #2e7d32; font-weight: bold; }
        
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        th { background-color: #f8f9fa; color: #666; text-transform: uppercase; font-size: 12px; }
        .type-badge { padding: 4px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; }
        .type-pay { background: #d4edda; color: #155724; }
        .type-transfer { background: #fff3cd; color: #856404; }
    </style>
</head>
<body>

<div class="container">
    <h1>Hello, <%= ((User)session.getAttribute("user")).getUsername() %></h1>
    
    <div class="balance-box">
        <strong>Total Savings:</strong><br>
        <span class="balance-amount">$<%= request.getAttribute("balance") %></span>
    </div>

    <h3>Recent Activity</h3>
    <table>
        <thead>
            <tr>
                <th>Date</th>
                <th>Type</th>
                <th>Description</th>
                <th>Amount</th>
            </tr>
        </thead>
        <tbody>
            <% 
                List<Map<String, Object>> history = (List<Map<String, Object>>) request.getAttribute("history");
                if (history != null && !history.isEmpty()) {
                    for (Map<String, Object> t : history) {
            %>
            <tr>
                <td style="font-size: 13px; color: #888;"><%= t.get("date") %></td>
                <td>
                    <span class="type-badge <%= t.get("type").equals("ATTENDANCE_PAY") ? "type-pay" : "type-transfer" %>">
                        <%= t.get("type") %>
                    </span>
                </td>
                <td><%= t.get("desc") %></td>
                <td style="font-weight: bold; color: #2e7d32;">+$<%= t.get("amount") %></td>
            </tr>
            <% 
                    }
                } else { 
            %>
            <tr><td colspan="4" style="text-align:center; color: #999;">No transactions yet. Mark attendance to earn!</td></tr>
            <% } %>
        </tbody>
    </table>
    
    <br><a href="login.html" style="color: #666;">Logout</a>
</div>

</body>
</html>