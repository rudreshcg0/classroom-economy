<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<html>
<head>
    <title>Mark Attendance - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/mark_attendance.css">
</head>
<body>

<div class="container">
    <div class="header">
        <div>
            <a href="teacherDashboard" style="text-decoration: none; color: #3182ce; font-weight: bold;">⬅ Back to Dashboard</a>
            <% Map<String, Object> cd = (Map<String, Object>)request.getAttribute("classDetails"); %>
            <h1 style="margin: 10px 0;">Marking: <%= cd.get("name") %></h1>
        </div>
        <div style="text-align: right;">
            <p style="margin: 0; color: #2d3748;">Pay Rate: <strong>$<%= cd.get("pay") %></strong></p>
        </div>
    </div>

    <div class="hint-box">
        <strong>Keyboard Shortcuts:</strong> ⬆⬇ to Navigate | <strong>Space</strong> to toggle Present/Absent | <strong>Enter</strong> to Submit
    </div>

    <form id="attendanceForm" action="markAttendance" method="POST">
        <input type="hidden" name="classId" value="<%= cd.get("id") %>">
        <input type="hidden" name="schoolId" value="${sessionScope.user.schoolId}">

        <table>
            <thead>
                <tr>
                    <th style="width: 80px; text-align: center;">
                        <input type="checkbox" id="masterAttendance" onclick="toggleAllAttendance(this)" style="transform: scale(1.2);">
                        <label for="masterAttendance" style="font-size: 10px; display: block; cursor: pointer;">All Present</label>
                    </th>
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
                <tr class="attendance-row">
                    <td style="text-align: center;">
                        <input type="checkbox" name="presentStudents" value="<%= s.getId() %>" class="attendance-check" style="transform: scale(1.4);">
                    </td>
                    <td><%= s.getRollNo() %></td>
                    <td><strong><%= s.getUsername() %></strong></td>
                    <td>$<%= s.getBalance() %></td>
                </tr>
                <% 
                        }
                    } else { 
                %>
                <tr><td colspan="4" style="text-align:center; padding: 40px;">No students linked to this class.</td></tr>
                <% } %>
            </tbody>
        </table>

        <% if(students != null && !students.isEmpty()) { %>
            <button type="submit" class="btn-pay">Submit Attendance & Process Payments</button>
        <% } %>
    </form>
</div>

<script src="${pageContext.request.contextPath}/js/mark_attendance.js"></script>
</body>
</html>