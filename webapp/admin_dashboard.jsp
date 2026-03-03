<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<!DOCTYPE html>
<html>
<head>
    <title>School Admin Hub - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/admin_dashboard.css">
    <style>
        .notif-badge { position: absolute; top: -5px; right: -5px; background: #ef4444; color: white; border-radius: 50%; padding: 2px 6px; font-size: 10px; font-weight: bold; border: 2px solid white; }
        .finance-card { border-left: 5px solid #10b981 !important; }
        .status-pill { padding: 4px 8px; border-radius: 6px; font-size: 11px; font-weight: bold; text-transform: uppercase; }
        .text-credit { color: #10b981 !important; font-weight: bold; }
        .text-debit { color: #ef4444 !important; font-weight: bold; }
    </style>
</head>
<body>

<c:set var="currentView" value="${not empty requestScope.currentView ? requestScope.currentView : 'management'}" />
<c:set var="activeTab" value="${not empty param.activeTab ? param.activeTab : 'panel-register'}" />

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin: 10px 0 0;">Admin: <strong><c:out value="${sessionScope.user.username}" /></strong></p>
    <hr style="border:0.5px solid #4a5568; margin: 15px 0;">
    <nav>
        <a href="adminDashboard?view=management" class="${currentView == 'management' ? 'active' : ''}">⚙️ Management</a>
        <a href="adminDashboard?view=finance" class="${currentView == 'finance' ? 'active' : ''}">💰 Finance & Limits</a>
        <a href="adminDashboard?view=ledger" class="${currentView == 'ledger' ? 'active' : ''}">📜 Financial Ledger</a>
        <hr style="border:0.5px solid #4a5568; margin: 20px 0;">
        <a href="login.jsp" style="color:#fc8181;">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    
    <c:choose>
        <c:when test="${currentView == 'management'}">
            <h1>School Management</h1>

            <div class="admin-actions">
                <button type="button" class="btn-tab" data-target="panel-register">Register Staff</button>
                <button type="button" class="btn-tab" data-target="panel-classlink">Class Setup & Linking</button>
                <button type="button" class="btn-tab" data-target="panel-registry">Class & Enrollment Management</button>
            </div>

            <div id="panel-register" class="action-panel hidden">
                <div class="card">
                    <h3>Register Staff</h3>
                    <form action="adminAction" method="POST">
                        <input type="hidden" name="action" value="addTeacher">
                        <input type="text" name="username" placeholder="Full Name" required>
                        <input type="password" name="password" placeholder="Password" required>
                        <button type="submit" class="btn-main" style="background:#3182ce; color:white;">Add Teacher Account</button>
                    </form>
                </div>
            </div>

            <div id="panel-classlink" class="action-panel hidden">
                <div class="card">
                    <h3>Class Setup & Linking</h3>
                    <form action="adminAction" method="POST">
                        <input type="hidden" name="action" value="addClass">
                        <div style="display:flex; gap:10px;">
                            <input type="text" name="className" placeholder="Class Name" required>
                            <input type="number" name="payRate" placeholder="Session Pay (₹)" step="0.1" required>
                        </div>
                        <button type="submit" class="btn-main" style="background:#38a169; color:white;">Create New Class</button>
                    </form>

                    <form action="adminAction" method="POST" style="border-top: 1px solid #eee; padding-top: 20px; margin-top: 20px;">
                        <input type="hidden" name="action" value="assignTeacher">
                        <label style="font-size:12px; font-weight:bold; color:#64748b;">ASSIGN TEACHER TO CLASS</label>
                        <select name="classId" required>
                            <option value="">Select Class</option>
                            <c:forEach var="c" items="${classList}">
                                <option value="<c:out value='${c.id}' />"><c:out value="${c.name}" /></option>
                            </c:forEach>
                        </select>
                        <select name="teacherId" required>
                            <option value="">Select Teacher to Link</option>
                            <c:forEach var="t" items="${schoolTeachers}">
                                <option value="<c:out value='${t.id}' />"><c:out value="${t.username}" /></option>
                            </c:forEach>
                        </select>
                        <button type="submit" class="btn-main" style="background:#805ad5; color:white;">Link Staff to Class</button>
                    </form>
                </div>
            </div>

            <div id="panel-registry" class="action-panel hidden">
                <div class="card">
                    <h3>Class & Enrollment Management</h3>
                    <form action="adminDashboard" method="GET" id="registryJump">
                        <input type="hidden" name="view" value="management">
                        <input type="hidden" name="activeTab" value="panel-registry">
                        <select name="classId" onchange="this.form.submit()">
                            <option value="">-- Choose Class to Manage --</option>
                            <c:forEach var="c" items="${classList}">
                                <option value="<c:out value='${c.id}' />" ${c.id == selectedClassId ? 'selected' : ''}>
                                    <c:out value="${c.name}" />
                                </option>
                            </c:forEach>
                        </select>
                    </form>

                    <c:if test="${not empty selectedClassId}">
                        <form action="adminAction" method="POST">
                            <input type="hidden" name="action" value="deleteUser">
                            
                            <div class="section-header">
                                <span>Assigned Staff</span>
                                <input type="text" class="search-mini" onkeyup="filterTable(this, 'teacherTable')" placeholder="Search staff...">
                            </div>
                            <table id="teacherTable">
                                <c:choose>
                                    <c:when test="${not empty classTeachers}">
                                        <c:forEach var="t" items="${classTeachers}">
                                            <tr>
                                                <td width="30px"><input type="checkbox" name="id" value="<c:out value='${t.id}' />"></td>
                                                <td><strong><c:out value="${t.username}" /></strong></td>
                                                <td align="right"><button type="button" class="btn-unlink" onclick="unlinkTeacher('<c:out value='${selectedClassId}' />')">Unlink</button></td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr><td colspan="3" style="text-align:center; color:#94a3b8;">No staff linked to this class.</td></tr>
                                    </c:otherwise>
                                </c:choose>
                            </table>

                            <div class="section-header">
                                <span>Enrolled Roster</span>
                                <input type="text" class="search-mini" onkeyup="filterTable(this, 'studentTable')" placeholder="Search students...">
                            </div>
                            <table id="studentTable">
                                <c:choose>
                                    <c:when test="${not empty classStudents}">
                                        <c:forEach var="s" items="${classStudents}">
                                            <tr>
                                                <td width="30px"><input type="checkbox" name="id" value="<c:out value='${s.id}' />"></td>
                                                <td><c:out value="${s.username}" /></td>
                                                <td align="right">Roll No: <c:out value="${s.rollNo}" /></td>
                                            </tr>
                                        </c:forEach>
                                    </c:when>
                                    <c:otherwise>
                                        <tr><td colspan="3" style="text-align:center; color:#94a3b8;">No students enrolled.</td></tr>
                                    </c:otherwise>
                                </c:choose>
                            </table>
                            
                            <button type="submit" class="btn-del" style="margin-top:25px; width:100%;" onclick="return confirm('WARNING: This will permanently delete selected accounts. Proceed?')">Terminate Selected Accounts</button>
                        </form>
                    </c:if>
                </div>
            </div>
        </c:when>

        <c:when test="${currentView == 'finance'}">
            <h1>Financial Controls</h1>
            <div style="display: grid; grid-template-columns: 1fr 320px; gap: 25px; align-items: start;">
                <div class="card finance-card">
                    <h3>Teacher Daily Soft Limits</h3>
                    <p style="color: #64748b; font-size: 13px; margin-bottom: 20px;">Control the maximum daily reward capacity. Teachers can request temporary increases.</p>
                    <table>
                        <thead>
                            <tr style="background:#f8fafc;">
                                <th>Teacher Name</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="t" items="${schoolTeachers}">
                                <tr>
                                    <td><strong><c:out value="${t.username}" /></strong></td>
                                    <td>
                                        <form action="adminAction" method="POST" style="display:flex; gap:8px; margin:0;">
                                            <input type="hidden" name="action" value="setDailyLimit">
                                            <input type="hidden" name="teacherId" value="<c:out value='${t.id}' />">
                                            <input type="hidden" name="view" value="finance">
                                            <input type="number" name="dailyLimit" placeholder="₹ 0.00" step="0.01" style="width: 110px; margin:0;" required>
                                            <button type="submit" class="btn-main" style="width: auto; padding: 8px 12px; margin:0; background: #10b981; color:white;">Update</button>
                                        </form>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>

                <div class="card" style="border-top: 4px solid #f59e0b; padding: 15px;">
                    <h3 style="margin:0 0 20px;">🔔 Extension Requests</h3>
                    <div id="requestContainer" class="scroll-area" style="max-height: 600px;">
                        <c:choose>
                            <c:when test="${not empty limitRequests}">
                                <c:forEach var="r" items="${limitRequests}">
                                    <div class="request-item card" style="padding:15px; margin-bottom:15px; border: 1px solid #fcd34d; background: #fffbeb;">
                                        <div style="font-weight: bold; font-size: 14px;"><c:out value="${r.teacher_name}" /></div>
                                        <div style="color: #d97706; font-weight: 800; font-size: 18px; margin: 5px 0;">+₹<c:out value="${r.amount}" /></div>
                                        <p style="font-size: 12px; color: #4b5563;">"<c:out value="${r.reason}" />"</p>
                                        <div style="display: flex; gap: 10px;">
                                            <form action="adminAction" method="POST" style="flex:1; margin:0;">
                                                <input type="hidden" name="action" value="handleLimitRequest">
                                                <input type="hidden" name="requestId" value="<c:out value='${r.id}' />">
                                                <input type="hidden" name="status" value="APPROVED">
                                                <input type="hidden" name="view" value="finance">
                                                <button type="submit" class="btn-main" style="background:#10b981; color:white; padding: 8px; font-size: 11px;">Approve</button>
                                            </form>
                                            <form action="adminAction" method="POST" style="flex:1; margin:0;">
                                                <input type="hidden" name="action" value="handleLimitRequest">
                                                <input type="hidden" name="requestId" value="<c:out value='${r.id}' />">
                                                <input type="hidden" name="status" value="REJECTED">
                                                <input type="hidden" name="view" value="finance">
                                                <button type="submit" class="btn-main" style="background:#ef4444; color:white; padding: 8px; font-size: 11px;">Deny</button>
                                            </form>
                                        </div>
                                    </div>
                                </c:forEach>
                            </c:when>
                            <c:otherwise>
                                <div style="text-align:center; padding:40px 10px;">☕ No pending requests.</div>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </div>
        </c:when>

        <c:otherwise>
            <jsp:include page="includes/admin_ledger.jsp" /> 
        </c:otherwise>
    </c:choose>
</div>

<form id="unlinkForm" action="adminAction" method="POST" style="display:none;">
    <input type="hidden" name="action" value="assignTeacher">
    <input type="hidden" name="classId" id="unlinkClassId">
    <input type="hidden" name="teacherId" value="0">
</form>

<script>
    window.ACTIVE_TAB_ID = "<c:out value='${activeTab}' />";
</script>
<script src="${pageContext.request.contextPath}/js/admin_dashboard.js"></script>
</body>
</html>