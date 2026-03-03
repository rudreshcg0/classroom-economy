<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Registry Management - VCES</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/teacher_dashboard.css">
</head>
<body>

<div class="sidebar">
    <h2>VCES Admin</h2>
    <p style="color: #a0aec0; margin-bottom: 20px;">Teacher: <strong>${sessionScope.user.username}</strong></p>
    <nav>
        <a href="teacherDashboard" class="sidebar-link">🏠 Dashboard Overview</a>
        <a href="markAttendance" class="sidebar-link">📝 Mark Attendance</a>
        <a href="teacherDashboard?tab=marketplace" class="sidebar-link">🏪 Marketplace Manager</a>
        <a href="manageStudents" class="sidebar-link active">👥 Student Registry</a>
        <a href="studentTransactions" class="sidebar-link">💰 Financial Ledger</a>
        <a href="login.jsp" class="sidebar-link logout">🚪 Logout</a>
    </nav>
</div>

<div class="main-content">
    <div class="nav-tabs">
        <button class="tab-btn active" onclick="switchTab('add')">Register & Enroll</button>
        <button class="tab-btn" onclick="switchTab('remove')">Terminate & Unenroll</button>
    </div>

    <div id="sectionAdd">
        <div style="display:grid; grid-template-columns: 1fr 1.5fr; gap: 25px;">
            <div class="card">
                <h3>New Registration</h3>
                <form action="manageStudents" method="POST">
                    <input type="hidden" name="action" value="register">
                    <p style="font-size: 12px; color: #64748b; margin-bottom: 10px;">Format: <strong>Name, Roll No, Email</strong></p>
                    <textarea name="studentData" placeholder="Example: Rudresh, 101, rudresh@example.com" required style="height: 200px;"></textarea>
                    <button type="submit" class="btn btn-primary" style="margin-top:15px;">Process Registration</button>
                </form>
            </div>

            <div class="card">
                <h3>Class Enrollment</h3>
                <form action="manageStudents" method="POST">
                    <input type="hidden" name="action" value="enroll">
                    <select name="classId" required>
                        <option value="">Select Target Class</option>
                        <% List<Map<String, Object>> classes = (List<Map<String, Object>>)request.getAttribute("classes");
                           if(classes != null) for(Map<String, Object> c : classes) { %>
                            <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                        <% } %>
                    </select>
                    
                    <div class="search-container" style="margin-top:10px;">
                        <span class="search-icon">🔍</span>
                        <input type="text" id="enrollSearch" onkeyup="filterEnrollList()" placeholder="Search students...">
                    </div>
                    
                    <div class="scroll-area" style="border: 1px solid #f1f5f9; padding:10px; border-radius:10px;">
                        <label style="display:block; padding-bottom: 10px; border-bottom: 1px solid #f1f5f9; margin-bottom: 10px; font-weight: bold;">
                            <input type="checkbox" onclick="toggleEnrollAll(this)"> Select Visible
                        </label>
                        <div id="enrollListBody">
                            <% List<User> studentList = (List<User>)request.getAttribute("students");
                               if(studentList != null) for(User s : studentList) { %>
                                <label class="enroll-item" style="display:block; padding: 8px 12px; border: 1px solid #f1f5f9; border-radius:8px; margin-bottom:5px; cursor: pointer;">
                                    <input type="checkbox" name="studentIds" value="<%= s.getId() %>"> <%= s.getUsername() %> [Roll: <%= s.getRollNo() %>]
                                </label>
                            <% } %>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-warning" style="margin-top:15px;">Confirm Enrollment</button>
                </form>
            </div>
        </div>
    </div>

    <div id="sectionRemove" class="hidden">
        <div class="card">
            <h3>Registry Management</h3>
            <div style="display:flex; gap: 15px; margin-bottom: 20px;">
                <select id="classFilter" onchange="applyRegistryFilter()" style="flex:1; margin-bottom:0;">
                    <option value="all">Full Registry (System Termination)</option>
                    <% if(classes != null) for(Map<String, Object> c : classes) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %> (Class Unenrollment)</option>
                    <% } %>
                </select>
                <input type="text" id="registrySearch" onkeyup="applyRegistryFilter()" placeholder="Search registry..." style="flex:1; margin-bottom:0;">
                <button type="button" class="btn btn-danger" onclick="executeRegistryAction()" id="batchBtn" style="padding: 0 25px;">Terminate Selected</button>
            </div>

            <form id="registryForm" action="manageStudents" method="POST">
                <input type="hidden" name="action" id="currentAction" value="terminate">
                <input type="hidden" name="classId" id="targetClassId">
                <table>
                    <thead>
                        <tr>
                            <th style="width:40px;"><input type="checkbox" id="regMaster" onclick="toggleRegistryAll(this)"></th>
                            <th>ID / Roll No</th>
                            <th>Username</th>
                            <th>Active Enrollments</th>
                        </tr>
                    </thead>
                    <tbody id="registryBody">
                        <% List<Map<String, Object>> enrolls = (List<Map<String, Object>>)request.getAttribute("enrollments");
                           if(studentList != null) for(User s : studentList) { 
                               String cIds = ""; String cNames = "";
                               if(enrolls != null) for(Map<String, Object> e : enrolls) {
                                   if((int)e.get("sId") == s.getId()) { cIds += e.get("cId") + ","; cNames += e.get("cName") + ", "; }
                               }
                        %>
                        <tr class="registry-row" data-enrollments="<%= cIds %>">
                            <td><input type="checkbox" name="studentIds" value="<%= s.getId() %>"></td>
                            <td><%= s.getRollNo() %></td>
                            <td><strong><%= s.getUsername() %></strong></td>
                            <td><small><%= cNames %></small></td>
                        </tr>
                        <% } %>
                    </tbody>
                </table>
            </form>
        </div>
    </div>
</div>

<script>
function switchTab(mode) {
    document.getElementById('sectionAdd').classList.toggle('hidden', mode !== 'add');
    document.getElementById('sectionRemove').classList.toggle('hidden', mode !== 'remove');
    document.querySelectorAll('.tab-btn').forEach((b, i) => b.classList.toggle('active', (i === 0 && mode === 'add') || (i === 1 && mode === 'remove')));
}
function filterEnrollList() {
    const q = document.getElementById('enrollSearch').value.toLowerCase();
    document.querySelectorAll('.enroll-item').forEach(item => item.style.display = item.innerText.toLowerCase().includes(q) ? 'block' : 'none');
}
function toggleEnrollAll(m) {
    document.querySelectorAll('#enrollListBody input').forEach(cb => { if(cb.closest('.enroll-item').style.display !== 'none') cb.checked = m.checked; });
}
function applyRegistryFilter() {
    const cId = document.getElementById('classFilter').value;
    const q = document.getElementById('registrySearch').value.toLowerCase();
    document.querySelectorAll('.registry-row').forEach(row => {
        const matchesClass = cId === 'all' || row.getAttribute('data-enrollments').split(',').includes(cId);
        const matchesSearch = row.innerText.toLowerCase().includes(q);
        row.style.display = matchesClass && matchesSearch ? '' : 'none';
    });
    const btn = document.getElementById('batchBtn');
    const act = document.getElementById('currentAction');
    if (cId === 'all') { btn.innerText = 'Terminate Selected'; btn.className = 'btn btn-danger'; act.value = 'terminate'; }
    else { btn.innerText = 'Unenroll from Class'; btn.className = 'btn btn-warning'; act.value = 'unenroll'; document.getElementById('targetClassId').value = cId; }
}
function toggleRegistryAll(m) {
    document.querySelectorAll('#registryBody input').forEach(cb => { if(cb.closest('tr').style.display !== 'none') cb.checked = m.checked; });
}
function executeRegistryAction() {
    const f = document.getElementById('registryForm');
    const n = f.querySelectorAll('input[name="studentIds"]:checked').length;
    if (n === 0) { alert('Please select records.'); return; }
    if (confirm('Execute for ' + n + ' students?')) f.submit();
}
</script>
</body>
</html>