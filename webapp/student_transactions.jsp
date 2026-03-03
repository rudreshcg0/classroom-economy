<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%@ taglib uri="jakarta.tags.core" prefix="c" %>
<%@ taglib uri="jakarta.tags.functions" prefix="fn" %>
<!DOCTYPE html>
<html>
<head>
    <title>Financial Audit - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/teacher_dashboard.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/ledger.css">
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin-bottom: 20px;">Teacher: <strong><c:out value="${sessionScope.user.username}" /></strong></p>
    <nav>
        <a href="teacherDashboard" class="sidebar-link">🏠 Dashboard Overview</a>
        <a href="markAttendance" class="sidebar-link">📝 Mark Attendance</a>
        <a href="teacherDashboard?tab=marketplace" class="sidebar-link">🏪 Marketplace Manager</a>
        <a href="manageStudents" class="sidebar-link">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link active">💰 Financial Ledger</a>
        <a href="login.jsp" class="sidebar-link logout">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    <div class="breadcrumb">
        <a href="studentTransactions">Ledger</a> 
        <c:if test="${not empty selectedClassId}"> &nbsp;>&nbsp; Class View </c:if>
        <c:if test="${not empty targetStudentName}"> &nbsp;>&nbsp; <c:out value="${targetStudentName}" /> </c:if>
    </div>

    <div class="card" style="max-width: 500px;">
        <h3>1. Audit by Class</h3>
        <form action="studentTransactions" method="GET">
            <select name="classId" onchange="this.form.submit()" class="search-input" style="padding-left: 10px;">
                <option value="">-- Choose Class to View Students --</option>
                <c:forEach var="c" items="${classes}">
                    <option value="<c:out value='${c.id}' />" ${c.id == selectedClassId ? 'selected' : ''}>
                        <c:out value="${c.name}" />
                    </option>
                </c:forEach>
            </select>
        </form>
    </div>

    <c:if test="${not empty students}">
        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px;">
                <h3 style="margin:0;">2. Students in Class</h3>
                <small style="color: #64748b;"><c:out value="${fn:length(students)}" /> Students Found</small>
            </div>
            
            <div class="search-container">
                <span class="search-icon">🔍</span>
                <input type="text" id="studentSearch" onkeyup="filterStudents()" class="search-input" placeholder="Search students by name or roll no...">
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Roll No</th>
                        <th>Name</th>
                        <th>Current Balance</th>
                    </tr>
                </thead>
                <tbody id="studentBody">
                    <c:forEach var="s" items="${students}">
                        <tr class="student-row">
                            <td><c:out value="${s.rollNo}" /></td>
                            <td>
                                <a href="studentTransactions?classId=<c:out value='${selectedClassId}' />&studentId=<c:out value='${s.id}' />" style="color:#3182ce; font-weight:600;">
                                    <c:out value="${s.username}" />
                                </a>
                            </td>
                            <td><strong class="text-credit">₹<c:out value="${fn:substringBefore(s.balance + 0.0001, '.')}${fn:substring(fn:substringAfter(s.balance + 0.0001, '.'), 0, 2)}" /></strong></td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
    </c:if>

    <c:if test="${not empty transactions}">
        <div class="card" style="border-top: 4px solid #3182ce;">
            <h3>3. History for: <c:out value="${targetStudentName}" /></h3>
            
            <div class="search-container">
                <span class="search-icon">🔍</span>
                <input type="text" id="txSearch" onkeyup="filterTransactions()" class="search-input" placeholder="Filter history...">
            </div>
            
            <table>
                <thead>
                    <tr>
                        <th>Date</th>
                        <th>Sender</th>
                        <th>Receiver</th>
                        <th>Amount</th>
                        <th>Type</th>
                    </tr>
                </thead>
                <tbody id="txBody">
                    <c:forEach var="t" items="${transactions}">
                        <c:set var="isCredit" value="${t.receiver == targetStudentName}" />
                        <tr class="tx-row">
                            <td><small style="color:#64748b;"><c:out value="${t.date}" /></small></td>
                            <td><c:out value="${t.sender}" /></td>
                            <td><c:out value="${t.receiver}" /></td>
                            <td class="${isCredit ? 'text-credit' : 'text-debit'}">
                                <c:out value="${isCredit ? '+' : '-'}" />₹<c:out value="${t.amount}" />
                            </td>
                            <td>
                                <c:set var="type" value="${t.type}" />
                                <span class="badge ${ (type == 'REWARD_DEDUCT' || type == 'DEBIT') ? 'bg-deduct' : 
                                                   (fn:contains(type, 'REWARD') || fn:toLowerCase(type) == 'salary' ? 'bg-salary' : 'bg-transfer') }">
                                    <c:out value="${fn:replace(type, '_', ' ')}" />
                                </span>
                            </td>
                        </tr>
                    </c:forEach>
                </tbody>
            </table>
        </div>
    </c:if>
</div>

<script src="${pageContext.request.contextPath}/js/ledger.js"></script>
</body>
</html>