<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
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
            <h1 style="margin: 10px 0;">Marking: <c:out value="${classDetails.name}" /></h1>
        </div>
        <div style="text-align: right;">
            <p style="margin: 0; color: #2d3748;">Pay Rate: <strong>₹<c:out value="${classDetails.pay}" /></strong></p>
        </div>
    </div>

    <div class="hint-box">
        <strong>Keyboard Shortcuts:</strong> ⬆⬇ to Navigate | <strong>Space</strong> to toggle Present/Absent | <strong>Enter</strong> to Submit
    </div>

    <form id="attendanceForm" action="markAttendance" method="POST">
        <input type="hidden" name="classId" value="<c:out value='${classDetails.id}' />">
        <input type="hidden" name="schoolId" value="<c:out value='${sessionScope.user.schoolId}' />">

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
                <c:choose>
                    <c:when test="${not empty students}">
                        <c:forEach var="s" items="${students}">
                            <tr class="attendance-row">
                                <td style="text-align: center;">
                                    <input type="checkbox" name="presentStudents" value="<c:out value='${s.id}' />" class="attendance-check" style="transform: scale(1.4);">
                                </td>
                                <td><c:out value="${s.rollNo}" /></td>
                                <td><strong><c:out value="${s.username}" /></strong></td>
                                <td>₹<c:out value="${s.balance}" /></td>
                            </tr>
                        </c:forEach>
                    </c:when>
                    <c:otherwise>
                        <tr><td colspan="4" style="text-align:center; padding: 40px;">No students linked to this class.</td></tr>
                    </c:otherwise>
                </c:choose>
            </tbody>
        </table>

        <c:if test="${not empty students}">
            <button type="submit" class="btn-pay">Submit Attendance & Process Payments</button>
        </c:if>
    </form>
</div>

<script src="${pageContext.request.contextPath}/js/mark_attendance.js"></script>
</body>
</html>