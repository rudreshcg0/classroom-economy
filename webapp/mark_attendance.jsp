<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<html>
<head>
    <title>Mark Attendance - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; padding: 40px; background: #f4f7f6; }
        .container { max-width: 800px; margin: auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
        .header { border-bottom: 2px solid #eee; margin-bottom: 20px; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        th { background: #3182ce; color: white; }
        .btn-pay { background: #38a169; color: white; border: none; padding: 15px 30px; border-radius: 8px; cursor: pointer; width: 100%; font-size: 16px; font-weight: bold; margin-top: 20px; }
        .btn-pay:hover { background: #2f855a; }
    </style>
</head>
<body>

<div class="container">
    <div class="header">
        <a href="teacherDashboard">⬅ Back</a>
        <% Map<String, Object> cd = (Map<String, Object>)request.getAttribute("classDetails"); %>
        <h1>Marking: <%= cd.get("name") %></h1>
        <p>Students present will be paid <strong>$<%= cd.get("pay") %></strong> instantly.</p>
    </div>

    <form action="markAttendance" method="POST">
        <input type="hidden" name="classId" value="<%= cd.get("id") %>">
        <input type="hidden" name="schoolId" value="${sessionScope.user.schoolId}">

        <table>
            <thead>
                <tr>
                    <th style="width: 50px;">Check</th>
                    <th>Roll No</th>
                    <th>Student Name</th>
                    <th>Wallet Balance</th>
                </tr>
            </thead>
            <tbody>
                <% 
                    List<User> students = (List<User>)request.getAttribute("students");
                    if(students != null && !students.isEmpty()) {
                        for(User s : students) { 
                %>
                <tr>
                    <td><input type="checkbox" name="presentStudents" value="<%= s.getId() %>" style="transform: scale(1.4);"></td>
                    <td><%= s.getRollNo() %></td>
                    <td><strong><%= s.getUsername() %></strong></td>
                    <td>$<%= s.getBalance() %></td>
                </tr>
                <% 
                        }
                    } else { 
                %>
                <tr><td colspan="4" style="text-align:center;">No students linked to this class. Go to Student Management to link them.</td></tr>
                <% } %>
            </tbody>
        </table>

        <% if(students != null && !students.isEmpty()) { %>
            <button type="submit" class="btn-pay">Submit Attendance & Process Payment</button>
        <% } %>
    </form>
</div>

</body>
</html>