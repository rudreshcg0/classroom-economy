<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.*, models.User" %>
<!DOCTYPE html>
<html>
<head>
    <title>Student Management Hub - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; background-color: #f7fafc; display: flex; }
        .sidebar { width: 250px; background: #1a202c; color: white; height: 100vh; padding: 25px; position: fixed; }
        .main-content { margin-left: 300px; padding: 40px; width: calc(100% - 340px); }
        .card { background: white; border-radius: 12px; padding: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.05); margin-bottom: 25px; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #edf2f7; }
        th { background: #f1f5f9; color: #475569; font-size: 12px; text-transform: uppercase; }
        .row-input { display: flex; gap: 10px; margin-bottom: 10px; }
        input, select { padding: 10px; border: 1px solid #e2e8f0; border-radius: 6px; width: 100%; }
        .btn { padding: 10px 15px; border-radius: 6px; border: none; cursor: pointer; font-weight: bold; color: white; transition: 0.3s; }
        .btn-add { background: #3182ce; }
        .btn-save { background: #38a169; width: 100%; margin-top: 10px; }
        .btn-del { background: #e53e3e; padding: 5px 10px; font-size: 11px; }
        .btn-link { background: #805ad5; width: 100%; margin-top: 10px; }
    </style>
</head>
<body>

<div class="sidebar">
    <h2>Teacher Tools</h2>
    <p>Logged in: <strong>${sessionScope.user.username}</strong></p>
    <hr style="border: 0.1px solid #4a5568; margin: 20px 0;">
    <a href="teacherDashboard" style="color: #cbd5e0; text-decoration: none; display: block; margin-bottom: 15px;">⬅ Back to Dashboard</a>
    <a href="login.html" style="color: #fc8181; text-decoration: none;">Logout</a>
</div>

<div class="main-content">
    <h1>Student Management Hub</h1>

    <div class="grid">
        <div class="card">
            <h3>+ Add Multiple Students</h3>
            <form action="manageStudents" method="POST">
                <input type="hidden" name="action" value="addBulk">
                <div id="studentRows">
                    <div class="row-input">
                        <input type="text" name="names" placeholder="Student Name" required>
                        <input type="text" name="rolls" placeholder="Roll No" required style="width: 100px;">
                    </div>
                </div>
                <button type="button" onclick="addRow()" class="btn btn-add">+ Add Another Row</button>
                <button type="submit" class="btn btn-save">Save All Students</button>
            </form>
        </div>

        <div class="card">
            <h3>🔗 Assign to Class</h3>
            <form action="manageStudents" method="POST">
                <input type="hidden" name="action" value="linkClass">
                <label>Select Student:</label>
                <select name="studentId" required style="margin-bottom: 15px;">
                    <option value="">-- Choose Student --</option>
                    <% List<User> students = (List<User>)request.getAttribute("students");
                       if(students != null) for(User s : students) { %>
                        <option value="<%= s.getId() %>"><%= s.getUsername() %> (<%= s.getRollNo() %>)</option>
                    <% } %>
                </select>

                <label>Select Class:</label>
                <select name="classId" required>
                    <option value="">-- Choose Class --</option>
                    <% List<Map<String, Object>> classes = (List<Map<String, Object>>)request.getAttribute("classes");
                       if(classes != null) for(Map<String, Object> c : classes) { %>
                        <option value="<%= c.get("id") %>"><%= c.get("name") %></option>
                    <% } %>
                </select>
                <button type="submit" class="btn btn-link">Assign to Class</button>
            </form>
        </div>
    </div>

    <div class="card">
        <h3>Current Class Enrollments</h3>
        <table>
            <thead>
                <tr><th>Student Name</th><th>Class Name</th><th>Action</th></tr>
            </thead>
            <tbody>
                <% List<Map<String, Object>> enrolls = (List<Map<String, Object>>)request.getAttribute("enrollments");
                   if(enrolls != null && !enrolls.isEmpty()) {
                       for(Map<String, Object> e : enrolls) { %>
                    <tr>
                        <td><%= e.get("sName") %></td>
                        <td><strong><%= e.get("cName") %></strong></td>
                        <td>
                            <form action="manageStudents" method="POST" style="display:inline;">
                                <input type="hidden" name="action" value="removeFromClass">
                                <input type="hidden" name="studentId" value="<%= e.get("sId") %>">
                                <input type="hidden" name="classId" value="<%= e.get("cId") %>">
                                <button type="submit" class="btn btn-del" onclick="return confirm('Remove from this class?')">Remove Link</button>
                            </form>
                        </td>
                    </tr>
                <% } } else { %>
                    <tr><td colspan="3">No students assigned to your classes yet.</td></tr>
                <% } %>
            </tbody>
        </table>
    </div>

    <div class="card">
        <h3>Master Student List (School-wide)</h3>
        <table>
            <thead>
                <tr><th>Roll No</th><th>Username</th><th>Action</th></tr>
            </thead>
            <tbody>
                <% if(students != null) for(User s : students) { %>
                    <tr>
                        <td><%= s.getRollNo() %></td>
                        <td><%= s.getUsername() %></td>
                        <td>
                            <form action="manageStudents" method="POST" style="display:inline;">
                                <input type="hidden" name="action" value="deleteStudent">
                                <input type="hidden" name="studentId" value="<%= s.getId() %>">
                                <button type="submit" class="btn btn-del" onclick="return confirm('PERMANENTLY delete this student from the whole system?')">Delete Permanently</button>
                            </form>
                        </td>
                    </tr>
                <% } %>
            </tbody>
        </table>
    </div>
</div>

<script>
    function addRow() {
        const container = document.getElementById('studentRows');
        const newRow = document.createElement('div');
        newRow.className = 'row-input';
        newRow.innerHTML = '<input type="text" name="names" placeholder="Student Name" required> ' +
                           '<input type="text" name="rolls" placeholder="Roll No" required style="width: 100px;">';
        container.appendChild(newRow);
    }
</script>

</body>
</html>