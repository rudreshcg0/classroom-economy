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
        <div style="display:grid; grid-template-columns: 1fr 1.5fr; gap: 20px;">
            <div class="card">
                <h3>New Registration</h3>
                <form action="manageStudents" method="POST">
                    <input type="hidden" name="action" value="register">
                    <p style="font-size: 0.85rem; color: #636e72; margin-bottom: 5px;">Format: <strong>Name, Roll No, Personal Email</strong></p>
                    <textarea name="studentData" placeholder="Rudresh, 101, rudresh@example.com" required style="height: 200px;"></textarea>
                    <button type="submit" class="btn btn-primary">Process Registration</button>
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
                    
                    <input type="text" id="enrollSearch" onkeyup="filterEnrollList()" placeholder="Search students..." class="search-bar" style="margin-top:10px;">
                    
                    <div class="scroll-area">
                        <label style="display:block; padding-bottom: 10px; border-bottom: 1px solid #eee; margin-bottom: 10px; font-weight: bold;">
                            <input type="checkbox" id="enrollMaster" onclick="toggleEnrollAll(this)"> Select All Visible
                        </label>
                        <div id="enrollListBody">
                            <% List<User> studentList = (List<User>)request.getAttribute("students");
                               if(studentList != null) for(User s : studentList) { %>
                                <label class="enroll-item" style="display:block; padding: 5px 0;">
                                    <input type="checkbox" name="studentIds" value="<%= s.getId() %>"> <%= s.getUsername() %> [Roll: <%= s.getRollNo() %>]
                                </label>
                            <% } %>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-warning">Confirm Enrollment</button>
                </form>
            </div>
        </div>
    </div>

    <div id="sectionRemove" class="hidden">
        <div class="card">
            <h3>Registry Management</h3>
            <div style="display:flex; gap: 15px; margin-bottom: 20px;">
                <select id="classFilter" onchange="applyRegistryFilter()" style="flex:1">
                    <option value="all">Full Registry (System Termination)</option>
                    <% if(classes != null) for(Map<String, Object> c : classes) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %> (Class Unenrollment)</option>
                    <% } %>
                </select>
                <input type="text" id="registrySearch" onkeyup="applyRegistryFilter()" placeholder="Search registry..." class="search-bar" style="flex:1; margin-bottom:0;">
                <button type="button" class="btn btn-danger" onclick="executeRegistryAction()" id="batchBtn" style="flex:0.5; margin-top:0;">Terminate Selected</button>
            </div>

            <form id="registryForm" action="manageStudents" method="POST">
                <input type="hidden" name="action" id="currentAction" value="terminate">
                <input type="hidden" name="classId" id="targetClassId">
                <table>
                    <thead>
                        <tr>
                            <th class="checkbox-cell"><input type="checkbox" id="regMaster" onclick="toggleRegistryAll(this)"></th>
                            <th>ID / Roll No</th>
                            <th>Credential / Username</th>
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
                            <td class="checkbox-cell"><input type="checkbox" name="studentIds" value="<%= s.getId() %>"></td>
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

<script src="${pageContext.request.contextPath}/js/teacher_dashboard.js"></script>
<script>
// Keep page-specific behavior (tabs, filters)
function switchTab(mode) {
    document.getElementById('sectionAdd').classList.toggle('hidden', mode !== 'add');
    document.getElementById('sectionRemove').classList.toggle('hidden', mode !== 'remove');
    document.querySelectorAll('.tab-btn').forEach((b, i) => b.classList.toggle('active', (i === 0 && mode === 'add') || (i === 1 && mode === 'remove')));
}

function filterEnrollList() {
    const q = document.getElementById('enrollSearch').value.toLowerCase();
    document.querySelectorAll('.enroll-item').forEach(item => item.style.display = item.innerText.toLowerCase().includes(q) ? 'block' : 'none');
}
function toggleEnrollAll(master) {
    document.querySelectorAll('#enrollListBody input[name="studentIds"]').forEach(cb => {
        if (cb.closest('.enroll-item').style.display !== 'none') cb.checked = master.checked;
    });
}

function applyRegistryFilter() {
    const classId = document.getElementById('classFilter').value;
    const search = document.getElementById('registrySearch').value.toLowerCase();
    const rows = document.querySelectorAll('.registry-row');
    document.getElementById('regMaster').checked = false;

    rows.forEach(row => {
        const matchesClass = classId === 'all' || row.getAttribute('data-enrollments').split(',').includes(classId);
        const matchesSearch = row.innerText.toLowerCase().includes(search);
        row.style.display = matchesClass && matchesSearch ? '' : 'none';
    });

    const btn = document.getElementById('batchBtn');
    const act = document.getElementById('currentAction');
    if (classId === 'all') {
        btn.innerText = 'Terminate Selected'; btn.className = 'btn btn-danger'; act.value = 'terminate';
    } else {
        btn.innerText = 'Unenroll from Class'; btn.className = 'btn btn-warning'; act.value = 'unenroll';
        document.getElementById('targetClassId').value = classId;
    }
}
function toggleRegistryAll(master) {
    document.querySelectorAll('#registryBody input[name="studentIds"]').forEach(cb => {
        if (cb.closest('tr').style.display !== 'none') cb.checked = master.checked;
    });
}

function executeRegistryAction() {
    const form = document.getElementById('registryForm');
    const checked = form.querySelectorAll('input[name="studentIds"]:checked').length;
    if (checked === 0) { alert('Please select records.'); return; }
    if (confirm('Execute selected operation for ' + checked + ' records?')) form.submit();
}
</script>
</body>
</html>