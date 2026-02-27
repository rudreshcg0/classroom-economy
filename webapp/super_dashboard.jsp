<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, utils.DBConnection, models.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || (!user.getRole().equals("platform_root"))) {
        response.sendRedirect("login.html");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Platform Management - VCES</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; background: #f4f7f6; padding: 40px; margin: 0; }
        .container { max-width: 1200px; margin: auto; }
        .card { background: white; padding: 25px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.08); margin-bottom: 25px; }
        h2, h3 { color: #2c3e50; margin-top: 0; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 25px; }
        table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        th, td { text-align: left; padding: 12px; border-bottom: 1px solid #eee; }
        th { background: #34495e; color: white; }
        input, select { padding: 12px; width: 100%; margin: 8px 0; border: 1px solid #ddd; border-radius: 6px; box-sizing: border-box; }
        .btn { padding: 10px 15px; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; transition: 0.3s; color: white; }
        .btn-save { background: #27ae60; width: 100%; }
        .btn-edit { background: #3498db; }
        .btn-del { background: #e74c3c; }
        .btn-orange { background: #f39c12; }
        .search-box { border: 2px solid #3498db; padding: 10px; width: 300px; float: right; margin-bottom: 10px; border-radius: 6px; }
    </style>
</head>
<body>
    <div class="container">
        <div style="display: flex; justify-content: space-between; align-items: center;">
            <h2>🌍 Platform Management Hub</h2>
            <p>Master: <strong><%= user.getUsername() %></strong> | <a href="login.jsp" style="color: #e74c3c;">Logout</a></p>
        </div>

        <div class="grid">
            <div class="card">
                <h3>+ Add New School</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchool">
                    <input type="text" name="schoolName" placeholder="School Name" required>
                    <button type="submit" class="btn btn-save">Create School</button>
                </form>
            </div>

            <div class="card">
                <h3>+ Appoint School Admin</h3>
                <form action="superAdminAction" method="POST">
                    <input type="hidden" name="action" value="createSchoolAdmin">
                    <input type="text" name="adminUser" placeholder="Admin Username" required>
                    <input type="password" name="adminPass" placeholder="Password" required>
                    <select name="schoolId" required>
                        <option value="">-- Assign to School --</option>
                        <% try (Connection conn = DBConnection.getConnection();
                               Statement st = conn.createStatement();
                               ResultSet rs = st.executeQuery("SELECT * FROM schools ORDER BY school_name")) {
                            while(rs.next()) { %>
                                <option value="<%= rs.getInt("school_id") %>"><%= rs.getString("school_name") %></option>
                        <% } } catch(Exception e) {} %>
                    </select>
                    <button type="submit" class="btn btn-save" style="background: #2980b9;">Assign Admin</button>
                </form>
            </div>
        </div>

        <div class="card">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <h3>Managed Schools & Admins</h3>
                <input type="text" id="schoolSearch" onkeyup="filterTable()" class="search-box" placeholder="🔍 Search school or admin...">
            </div>
            <table id="schoolTable">
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>School Name</th>
                        <th>Appointed Admin</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% 
                    String sql = "SELECT s.school_id, s.school_name, u.username AS admin_name, u.user_id AS admin_id " +
                                 "FROM schools s LEFT JOIN users u ON s.school_id = u.school_id AND u.role = 'school_admin' " +
                                 "ORDER BY s.school_id";
                    try (Connection conn = DBConnection.getConnection();
                         Statement st = conn.createStatement();
                         ResultSet rs = st.executeQuery(sql)) {
                        while(rs.next()) { 
                            String adminName = rs.getString("admin_name");
                    %>
                    <tr>
                        <td><%= rs.getInt("school_id") %></td>
                        <td><strong><%= rs.getString("school_name") %></strong></td>
                        <td><%= (adminName != null) ? "👤 " + adminName : "<em>Unassigned</em>" %></td>
                        <td>
                            <div style="display: flex; gap: 8px;">
                                <button onclick="editSchool(<%= rs.getInt("school_id") %>, '<%= rs.getString("school_name") %>')" class="btn btn-edit">✏️ Rename</button>
                                
                                <form action="superAdminAction" method="POST" onsubmit="return confirm('DELETE SCHOOL? This wipes all data.')">
                                    <input type="hidden" name="action" value="deleteSchool">
                                    <input type="hidden" name="schoolId" value="<%= rs.getInt("school_id") %>">
                                    <button type="submit" class="btn btn-del">🗑️ School</button>
                                </form>

                                <% if (adminName != null) { %>
                                <form action="superAdminAction" method="POST" onsubmit="return confirm('Remove this Admin?')">
                                    <input type="hidden" name="action" value="deleteAdmin">
                                    <input type="hidden" name="adminId" value="<%= rs.getInt("admin_id") %>">
                                    <button type="submit" class="btn btn-orange">👤 Reset Admin</button>
                                </form>
                                <% } %>
                            </div>
                        </td>
                    </tr>
                    <% } } catch(Exception e) {} %>
                </tbody>
            </table>
        </div>
    </div>

    <form id="editForm" action="superAdminAction" method="POST" style="display:none;">
        <input type="hidden" name="action" value="editSchool">
        <input type="hidden" name="schoolId" id="editSchoolId">
        <input type="hidden" name="newName" id="editNewName">
    </form>

    <script>
        function editSchool(id, currentName) {
            let newName = prompt("Enter new name for " + currentName + ":", currentName);
            if (newName && newName !== currentName) {
                document.getElementById('editSchoolId').value = id;
                document.getElementById('editNewName').value = newName;
                document.getElementById('editForm').submit();
            }
        }

        function filterTable() {
            let filter = document.getElementById("schoolSearch").value.toUpperCase();
            let rows = document.getElementById("schoolTable").getElementsByTagName("tr");
            for (let i = 1; i < rows.length; i++) {
                let text = rows[i].innerText.toUpperCase();
                rows[i].style.display = text.indexOf(filter) > -1 ? "" : "none";
            }
        }
    </script>
</body>
</html>