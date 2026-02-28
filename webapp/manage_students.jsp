<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Registry Management - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f8f9fa; margin: 0; padding: 20px; display: flex; }
        .sidebar { width: 240px; background: #2d3436; color: white; height: 100vh; padding: 25px; position: fixed; left: 0; top: 0; }
        .main-content { margin-left: 270px; width: 100%; max-width: 1200px; }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .nav-tabs { display: flex; gap: 5px; margin-bottom: 20px; border-bottom: 2px solid #dee2e6; }
        .tab-btn { padding: 12px 30px; border: none; background: none; cursor: pointer; font-weight: 600; color: #636e72; border-bottom: 3px solid transparent; }
        .tab-btn.active { color: #0984e3; border-bottom-color: #0984e3; }
        .hidden { display: none; }
        textarea, select, .search-bar { width: 100%; padding: 12px; border: 1px solid #dfe6e9; border-radius: 8px; box-sizing: border-box; }
        .btn { padding: 12px 24px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; color: white; width: 100%; margin-top: 10px; }
        .btn-primary { background: #0984e3; } .btn-danger { background: #d63031; } .btn-warning { background: #6c5ce7; }
        table { width: 100%; border-collapse: collapse; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #f1f2f6; }
        .checkbox-cell { width: 30px; text-align: center; }
        .scroll-area { max-height: 250px; overflow-y: auto; border: 1px solid #dfe6e9; padding: 10px; border-radius: 8px; margin-top: 10px; }
    </style>
</head>
<body>

<div class="sidebar">
    <h3>VCES Admin</h3>
    <hr style="border: 0.5px solid #636e72;">
    <a href="teacherDashboard" style="color: #dfe6e9; text-decoration: none; display: block; margin: 20px 0;">Dashboard</a>
    <a href="login.jsp" style="color: #ff7675; text-decoration: none;">Logout</a>
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

<script>
function switchTab(mode) {
    document.getElementById('sectionAdd').classList.toggle('hidden', mode !== 'add');
    document.getElementById('sectionRemove').classList.toggle('hidden', mode !== 'remove');
    document.querySelectorAll('.tab-btn').forEach((b, i) => b.classList.toggle('active', (i === 0 && mode === 'add') || (i === 1 && mode === 'remove')));
}

function filterEnrollList() {
    const q = document.getElementById('enrollSearch').value.toLowerCase();
    document.querySelectorAll('.enroll-item').forEach(item => item.style.display = item.innerText.toLowerCase().includes(q) ? "block" : "none");
}
function toggleEnrollAll(master) {
    document.querySelectorAll('#enrollListBody input[name="studentIds"]').forEach(cb => {
        if(cb.closest('.enroll-item').style.display !== "none") cb.checked = master.checked;
    });
}

function applyRegistryFilter() {
    const classId = document.getElementById('classFilter').value;
    const search = document.getElementById('registrySearch').value.toLowerCase();
    const rows = document.querySelectorAll('.registry-row');
    document.getElementById('regMaster').checked = false;

    rows.forEach(row => {
        const matchesClass = (classId === "all" || row.getAttribute('data-enrollments').split(',').includes(classId));
        const matchesSearch = row.innerText.toLowerCase().includes(search);
        row.style.display = (matchesClass && matchesSearch) ? "" : "none";
    });

    const btn = document.getElementById('batchBtn');
    const act = document.getElementById('currentAction');
    if (classId === "all") {
        btn.innerText = "Terminate Selected"; btn.className = "btn btn-danger"; act.value = "terminate";
    } else {
        btn.innerText = "Unenroll from Class"; btn.className = "btn btn-warning"; act.value = "unenroll";
        document.getElementById('targetClassId').value = classId;
    }
}
function toggleRegistryAll(master) {
    document.querySelectorAll('#registryBody input[name="studentIds"]').forEach(cb => {
        if(cb.closest('tr').style.display !== "none") cb.checked = master.checked;
    });
}

function executeRegistryAction() {
    const form = document.getElementById('registryForm');
    const checked = form.querySelectorAll('input[name="studentIds"]:checked').length;
    if (checked === 0) { alert("Please select records."); return; }
    if (confirm("Execute selected operation for " + checked + " records?")) form.submit();
}
</script>
</body>
</html>